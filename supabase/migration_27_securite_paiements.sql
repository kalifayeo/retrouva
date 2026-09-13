-- =========================================================
-- RETROUVA — Migration 27 : sécurisation du flux de dons / paiement
-- =========================================================
-- Entièrement additive et idempotente (peut être relancée sans risque).
--
-- Corrigé : contrairement à la version précédente de ce fichier, celle-ci
-- ne suppose plus que la migration 20 a déjà été exécutée. Si vous aviez
-- l'erreur "relation donations does not exist", c'est parce que les
-- tables "payment_methods"/"donations" n'existaient pas encore chez vous
-- — cette version les crée d'abord si besoin (identique à la migration
-- 20), puis applique les correctifs de sécurité par-dessus. Si vous avez
-- déjà exécuté la migration 20 avec succès, cette migration ne fait que
-- compléter ce qui manque, sans rien dupliquer ni écraser.
--
-- Ce que corrige cette migration :
-- 1) On ne peut plus se fier au simple retour navigateur (?paiement=succes)
--    pour savoir si un don est payé : on trace maintenant la référence
--    fournisseur (order_id / referenceId / session id Wave) sur la ligne
--    "donations", pour pouvoir la retrouver et vérifier son vrai statut
--    côté serveur.
-- 2) Idempotence des webhooks : "payment_webhook_events" empêche qu'un
--    même événement (rejoué par erreur, ou par un attaquant) ne soit
--    traité deux fois (ex. compter deux fois le même don).
-- 3) La création d'un don ne se fait plus directement depuis le
--    navigateur (policy RLS ouverte à tous) mais via une route serveur
--    (server/api/dons/creer.post.js) qui applique une limite de
--    fréquence par IP. La policy d'insertion publique est donc retirée ;
--    seul le rôle "service_role" (utilisé par le serveur) peut insérer.
-- =========================================================

-- ---------------------------------------------------------
-- 0) Tables de base — créées seulement si elles n'existent pas encore
--    (reprise à l'identique de migration_20_dons_video_badge_pub.sql)
-- ---------------------------------------------------------
create table if not exists payment_methods (
  id uuid primary key default uuid_generate_v4(),
  nom text not null,
  type text not null default 'mobile_money',
  numero text not null,
  instructions text,
  icone text not null default 'card',
  ordre integer not null default 0,
  actif boolean not null default true,
  created_by uuid references profiles(id),
  created_at timestamptz not null default now()
);

create table if not exists donations (
  id uuid primary key default uuid_generate_v4(),
  reference text not null unique,
  nom_donateur text,
  telephone_donateur text,
  montant numeric(12,2) not null check (montant > 0),
  payment_method_id uuid references payment_methods(id),
  message text,
  statut text not null default 'en_attente',
  confirmed_by uuid references profiles(id),
  confirmed_at timestamptz,
  created_at timestamptz not null default now()
);

alter table payment_methods enable row level security;
alter table donations enable row level security;

-- Policies de base (identiques à la migration 20), rejouables sans
-- erreur grâce au "drop policy if exists" — convention déjà utilisée
-- ailleurs dans ce projet (voir migration_02, migration_18...).
drop policy if exists "payment_methods_lecture" on payment_methods;
create policy "payment_methods_lecture" on payment_methods for select using (actif = true or is_admin());

drop policy if exists "payment_methods_ecriture" on payment_methods;
create policy "payment_methods_ecriture" on payment_methods for all using (is_admin()) with check (is_admin());

drop policy if exists "donations_lecture_admin" on donations;
create policy "donations_lecture_admin" on donations for select using (is_admin());

drop policy if exists "donations_maj_admin" on donations;
create policy "donations_maj_admin" on donations for update using (is_admin());

create index if not exists idx_donations_statut on donations (statut, created_at desc);

-- Numéros par défaut, seulement si la table est vide (première création).
insert into payment_methods (nom, type, numero, instructions, icone, ordre)
select * from (values
  ('Orange Money', 'mobile_money', '+225 07 97 67 65 45', 'Composez #144# puis suivez les instructions pour envoyer vers ce numéro.', 'card', 1),
  ('MTN Mobile Money', 'mobile_money', '+225 05 46 22 97 78', 'Composez *133# puis suivez les instructions pour envoyer vers ce numéro.', 'card', 2),
  ('Wave', 'wave', '+225 07 97 67 65 45', 'Ouvrez l''application Wave, choisissez "Envoyer" puis saisissez ce numéro.', 'card', 3)
) as v(nom, type, numero, instructions, icone, ordre)
where not exists (select 1 from payment_methods);

-- ---------------------------------------------------------
-- 1) Traçabilité fournisseur + anti-fraude sur "donations"
-- ---------------------------------------------------------
alter table donations add column if not exists provider text; -- 'orange' | 'mtn' | 'wave' | null (don manuel)
alter table donations add column if not exists provider_reference text; -- order_id / referenceId MTN / id de session Wave
alter table donations add column if not exists provider_transaction_id text; -- txnid Orange, financialTransactionId MTN, id Wave...
alter table donations add column if not exists verified_at timestamptz; -- horodatage de la vérification serveur (pas juste "confirmé à l'oeil")
alter table donations add column if not exists ip_creation text; -- IP d'origine, pour la limite de fréquence anti-spam
alter table donations add column if not exists provider_metadata jsonb; -- ex. { "pay_token": "..." } nécessaire à la vérification Orange

create unique index if not exists idx_donations_provider_reference
  on donations (provider_reference)
  where provider_reference is not null;

create index if not exists idx_donations_ip_creation_date
  on donations (ip_creation, created_at desc);

-- ---------------------------------------------------------
-- 2) Idempotence des webhooks (Orange / Wave / MTN)
-- ---------------------------------------------------------
create table if not exists payment_webhook_events (
  id uuid primary key default uuid_generate_v4(),
  provider text not null,       -- 'orange' | 'wave' | 'mtn'
  event_id text not null,       -- identifiant unique fourni par le fournisseur (ou calculé)
  ip_source text,
  payload jsonb,
  created_at timestamptz not null default now(),
  unique (provider, event_id)
);

alter table payment_webhook_events enable row level security;
-- Aucune policy publique : seul service_role (le serveur) y touche, il
-- contourne RLS de toute façon. On garde RLS activée par défaut-sûr.

-- ---------------------------------------------------------
-- 3) Retrait de l'insertion publique directe sur "donations"
-- ---------------------------------------------------------
-- Avant : n'importe qui (même non connecté) pouvait insérer une ligne
-- directement depuis le navigateur, sans aucune limite de fréquence.
-- Désormais la création passe par server/api/dons/creer.post.js, qui
-- vérifie le montant, le format du téléphone, ET une limite de fréquence
-- par IP avant d'insérer via la clé service_role (qui contourne RLS).
drop policy if exists "donations_creation" on donations;

-- ---------------------------------------------------------
-- 4) Lecture publique restreinte pour la page de retour /don
-- ---------------------------------------------------------
-- La page /don a besoin de savoir si SON don (par référence qu'elle
-- connaît déjà) est confirmé, sans pouvoir lister ou lire les dons des
-- autres. On ne passe pas par une policy RLS pour ça (trop dangereux à
-- exprimer proprement en SQL sans exposer un scan par référence) : la
-- vérification se fait via server/api/dons/verifier.get.js, qui utilise
-- service_role côté serveur et ne renvoie que statut + montant, jamais
-- les coordonnées du donateur.
