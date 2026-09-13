-- =========================================================
-- RETROUVA — Migration 28 : reçus de don, historique donateur,
-- notifications push réelles, attestations de don entreprise
-- =========================================================
-- Entièrement additive et idempotente (relançable sans risque). Ne
-- suppose que la migration 27 est déjà passée (colonnes provider_*) ;
-- fonctionne aussi si vous partez directement de schema.sql à jour.

-- ---------------------------------------------------------
-- 1) DONS — donateur identifié, e-mail de reçu, mode entreprise
-- ---------------------------------------------------------
-- "donor_user_id" relie un don au compte connecté au moment du don (s'il
-- y en avait un) : permet à un utilisateur de retrouver l'historique de
-- SES dons sur /mes-dons, sans jamais rendre les dons des autres visibles
-- (policy de lecture ci-dessous, restreinte à donor_user_id = auth.uid()).
-- "email_donateur" est nécessaire pour envoyer un reçu — distinct de
-- l'e-mail du compte, car un don reste possible sans être connecté.
-- "type_donateur" distingue un don d'entreprise partenaire, qui peut
-- demander une attestation/reçu fiscal nominatif (raison sociale).
alter table donations add column if not exists donor_user_id uuid references profiles(id) on delete set null;
alter table donations add column if not exists email_donateur text;
alter table donations add column if not exists type_donateur text not null default 'particulier'; -- 'particulier' | 'entreprise'
alter table donations add column if not exists raison_sociale text; -- nom de l'entreprise si type_donateur = 'entreprise'
alter table donations add column if not exists recu_envoye_at timestamptz; -- horodatage du dernier envoi de reçu (email/SMS)
alter table donations add column if not exists recu_erreur text; -- dernier message d'erreur d'envoi, pour diagnostic admin

create index if not exists idx_donations_donor_user on donations (donor_user_id, created_at desc) where donor_user_id is not null;

-- Un donateur connecté peut consulter l'historique de SES dons (montant,
-- statut, date, moyen de paiement) — jamais ceux des autres. La création
-- (server/api/dons/creer.post.js, clé service_role) reste la seule voie
-- d'écriture, cette policy ne couvre que la lecture.
drop policy if exists "donations_lecture_donateur" on donations;
create policy "donations_lecture_donateur" on donations for select using (donor_user_id = auth.uid());

-- ---------------------------------------------------------
-- 2) NOTIFICATIONS PUSH — jetons d'appareil (Capacitor push-notifications)
-- ---------------------------------------------------------
-- Une ligne par appareil enregistré (un utilisateur peut avoir plusieurs
-- appareils). "plateforme" distingue android/ios pour un éventuel envoi
-- via des services différents plus tard. Le jeton est fourni par
-- Capacitor (FCM sur Android, APNs via FCM sur iOS) lors de
-- l'enregistrement — voir composables/usePushNotifications.js.
create table if not exists push_tokens (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references profiles(id) on delete cascade,
  jeton text not null,
  plateforme text not null default 'inconnue', -- 'android' | 'ios' | 'inconnue'
  derniere_utilisation timestamptz not null default now(),
  created_at timestamptz not null default now(),
  unique (user_id, jeton)
);

alter table push_tokens enable row level security;

-- Chacun ne gère que ses propres jetons (enregistrement/suppression
-- depuis son propre appareil) ; l'envoi effectif des pushes se fait côté
-- serveur avec la clé service_role (server/utils/envoyerPush.js), qui
-- contourne RLS de toute façon.
drop policy if exists "push_tokens_gestion_soi" on push_tokens;
create policy "push_tokens_gestion_soi" on push_tokens for all
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

create index if not exists idx_push_tokens_user on push_tokens (user_id);

-- ---------------------------------------------------------
-- 3) SUIVI DES ATTESTATIONS DE DON (reçu fiscal / entreprise)
-- ---------------------------------------------------------
-- Ne stocke pas le PDF lui-même (généré à la volée, voir
-- server/api/admin/dons/[id]/attestation.get.js et
-- server/api/dons/mes-dons/[id]/attestation.get.js) mais trace qui a émis
-- une attestation et quand, pour l'affichage admin ("attestation déjà
-- générée le ...") et un futur numéro de série si besoin.
alter table donations add column if not exists attestation_generee_at timestamptz;
alter table donations add column if not exists attestation_numero text unique;

-- Numéro d'attestation lisible, ex. RETROUVA-2026-000042 — généré une
-- seule fois, au premier appel de la route de génération (jamais
-- recalculé ensuite, pour qu'un même don garde toujours le même numéro).
create sequence if not exists attestation_numero_seq start 1;

-- Fonction appelée par server/utils/attestationPdf.js (via supabase.rpc)
-- pour obtenir le numéro d'attestation d'un don, en le créant s'il
-- n'existe pas encore. "security definer" + exécution atomique en une
-- seule fonction évite toute course (deux générations simultanées ne
-- peuvent pas produire deux numéros différents pour le même don).
create or replace function generer_numero_attestation(p_don_id uuid)
returns text
language plpgsql
security definer
as $$
declare
  v_numero text;
  v_annee text := to_char(now(), 'YYYY');
begin
  select attestation_numero into v_numero from donations where id = p_don_id;
  if v_numero is not null then
    return v_numero;
  end if;

  v_numero := 'RETROUVA-' || v_annee || '-' || lpad(nextval('attestation_numero_seq')::text, 6, '0');

  update donations
  set attestation_numero = v_numero, attestation_generee_at = now()
  where id = p_don_id;

  return v_numero;
end;
$$;
