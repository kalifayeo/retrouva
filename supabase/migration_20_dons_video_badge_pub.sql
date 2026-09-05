-- =========================================================
-- RETROUVA — Migration 20 : dons + paiement, vidéo de première
-- connexion, notification de badge confiance, publicité entreprises
-- =========================================================
-- Entièrement additive : aucune table existante n'est supprimée ni
-- renommée, aucune colonne existante n'est retirée. Peut être exécutée
-- sans risque sur une base qui a déjà toutes les migrations 02 à 19.
-- =========================================================

-- ---------------------------------------------------------
-- 1) BADGE CONFIANCE — notification automatique + correctif
-- ---------------------------------------------------------
-- Jusqu'ici, le badge "profil complet" n'était visible qu'en revenant
-- sur /profil, sans jamais prévenir l'utilisateur au moment où il vient
-- de le débloquer. On ajoute une colonne pour ne notifier qu'UNE seule
-- fois, et un déclencheur qui insère une notification (même mécanisme
-- que les correspondances/messages, migration_16) dès que le profil
-- devient complet.
--
-- Important : la commune n'a de sens que pour la ville "Abidjan" (seule
-- ville avec un découpage en communes dans l'app, voir
-- composables/useObjectTypes.js). La version précédente comptait la
-- commune comme obligatoire pour TOUT LE MONDE : un utilisateur de
-- Bouaké, Daloa, etc. ne pouvait donc jamais atteindre 100 % et ne
-- débloquait jamais le badge. Le déclencheur ci-dessous corrige ce
-- calcul côté base de données ; le correctif équivalent est appliqué
-- côté interface dans pages/profil.vue.

alter table profiles add column if not exists badge_confiance_notifie boolean not null default false;

create or replace function profil_est_complet(p profiles)
returns boolean
language sql
immutable
as $$
  select p.nom_affiche is not null and p.nom_affiche <> ''
     and p.telephone is not null and p.telephone <> ''
     and p.ville is not null and p.ville <> ''
     and p.avatar_url is not null and p.avatar_url <> ''
     and (p.ville is distinct from 'Abidjan' or (p.commune is not null and p.commune <> ''));
$$;

create or replace function notifier_badge_confiance()
returns trigger
language plpgsql
security definer
as $$
begin
  if profil_est_complet(new) and not coalesce(old.badge_confiance_notifie, false) then
    insert into notifications (user_id, titre, corps, type, lien)
    values (
      new.id,
      '🎁 Badge confiance débloqué',
      'Votre profil est désormais complet : les personnes avec qui vous échangez vous font davantage confiance.',
      'badge',
      '/profil'
    );
    new.badge_confiance_notifie := true;
  elsif not profil_est_complet(new) and coalesce(old.badge_confiance_notifie, false) then
    -- Si l'utilisateur retire une information (ex : supprime sa photo),
    -- le badge redevient à débloquer plus tard.
    new.badge_confiance_notifie := false;
  end if;
  return new;
end;
$$;

drop trigger if exists trg_notifier_badge_confiance on profiles;
create trigger trg_notifier_badge_confiance
  before update on profiles
  for each row
  execute function notifier_badge_confiance();

-- ---------------------------------------------------------
-- 2) DONS — moyens de paiement gérés par l'admin + suivi des dons
-- ---------------------------------------------------------
-- "payment_methods" remplace les numéros codés en dur de pages/don.vue
-- par une liste modifiable depuis /admin/dons, sans jamais perdre les
-- numéros déjà en place (ils sont repris tels quels dans le seed
-- ci-dessous). "donations" garde une trace de chaque don annoncé par un
-- visiteur (aucune passerelle de paiement réelle n'étant configurée
-- dans ce projet, il s'agit d'un enregistrement d'intention que
-- l'équipe RETROUVA confirme manuellement après réception).

create table if not exists payment_methods (
  id uuid primary key default uuid_generate_v4(),
  nom text not null,                    -- ex : "Orange Money"
  type text not null default 'mobile_money', -- 'mobile_money' | 'wave' | 'autre'
  numero text not null,                 -- numéro / identifiant à afficher
  instructions text,                    -- ex : code USSD, marche à suivre
  icone text not null default 'card',
  ordre integer not null default 0,
  actif boolean not null default true,
  created_by uuid references profiles(id),
  created_at timestamptz not null default now()
);

create table if not exists donations (
  id uuid primary key default uuid_generate_v4(),
  reference text not null unique,       -- généré côté client, montré au donateur
  nom_donateur text,
  telephone_donateur text,
  montant numeric(12,2) not null check (montant > 0),
  payment_method_id uuid references payment_methods(id),
  message text,
  statut text not null default 'en_attente', -- 'en_attente' | 'confirme' | 'annule'
  confirmed_by uuid references profiles(id),
  confirmed_at timestamptz,
  created_at timestamptz not null default now()
);

alter table payment_methods enable row level security;
alter table donations enable row level security;

-- Les moyens de paiement actifs sont visibles par tout le monde (page
-- publique /don), l'administration seule peut les modifier.
create policy "payment_methods_lecture" on payment_methods for select using (actif = true or is_admin());
create policy "payment_methods_ecriture" on payment_methods for all using (is_admin()) with check (is_admin());

-- N'importe quel visiteur (connecté ou non) peut annoncer un don ; seule
-- l'équipe d'administration peut ensuite consulter/mettre à jour la
-- liste (les coordonnées d'un donateur ne doivent pas être publiques).
create policy "donations_creation" on donations for insert with check (true);
create policy "donations_lecture_admin" on donations for select using (is_admin());
create policy "donations_maj_admin" on donations for update using (is_admin());

create index if not exists idx_donations_statut on donations (statut, created_at desc);

-- Reprise à l'identique des numéros déjà affichés sur /don, pour ne
-- rien changer visuellement tant que l'admin n'a pas modifié quoi que
-- ce soit dans /admin/dons.
insert into payment_methods (nom, type, numero, instructions, icone, ordre)
select * from (values
  ('Orange Money', 'mobile_money', '+225 07 97 67 65 45', 'Composez #144# puis suivez les instructions pour envoyer vers ce numéro.', 'card', 1),
  ('MTN Mobile Money', 'mobile_money', '+225 05 46 22 97 78', 'Composez *133# puis suivez les instructions pour envoyer vers ce numéro.', 'card', 2),
  ('Wave', 'wave', '+225 07 97 67 65 45', 'Ouvrez l''application Wave, choisissez "Envoyer" puis saisissez ce numéro.', 'card', 3)
) as v(nom, type, numero, instructions, icone, ordre)
where not exists (select 1 from payment_methods);

-- ---------------------------------------------------------
-- 3) VIDÉO DE PRÉSENTATION — première connexion sur un appareil
-- ---------------------------------------------------------
-- Réglage unique (une seule ligne), à l'image de "site_settings", géré
-- depuis /admin/introduction. Désactivé par défaut : tant que l'admin
-- n'a pas renseigné de lien vidéo et activé l'option, rien ne change
-- pour les utilisateurs (comportement actuel préservé).
create table if not exists intro_video_config (
  id text primary key default 'principal',
  actif boolean not null default false,
  titre text not null default 'Découvrez RETROUVA en vidéo',
  video_url text,
  position text not null default 'avant', -- 'avant' | 'apres' les diapositives d'introduction
  updated_by uuid references profiles(id),
  updated_at timestamptz not null default now()
);

alter table intro_video_config enable row level security;

create policy "intro_video_lecture" on intro_video_config for select using (true);
create policy "intro_video_ecriture" on intro_video_config for all using (is_admin()) with check (is_admin());

insert into intro_video_config (id) values ('principal') on conflict (id) do nothing;

-- ---------------------------------------------------------
-- 4) PUBLICITÉ DES ENTREPRISES — bannières & pop-up
-- ---------------------------------------------------------
-- Colonnes additives (nullables) pour que l'admin puisse identifier
-- clairement un encart comme une publicité payée par une entreprise
-- partenaire, sans rien changer aux annonces déjà en place.
alter table banners add column if not exists nom_entreprise text;
alter table banners add column if not exists contact_entreprise text;
alter table popups add column if not exists nom_entreprise text;
alter table popups add column if not exists contact_entreprise text;
