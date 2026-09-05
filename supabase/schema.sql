-- =========================================================
-- RETROUVA — Schéma PostgreSQL / Supabase (MVP)
-- Trouver. Connecter. Restituer.
-- =========================================================
-- À exécuter dans l'éditeur SQL de Supabase, ou via la CLI :
--   supabase db push
-- =========================================================

create extension if not exists "uuid-ossp";

-- ---------------------------------------------------------
-- ENUMS
-- ---------------------------------------------------------
create type user_role as enum ('utilisateur', 'utilisateur_verifie', 'moderateur', 'administrateur', 'partenaire', 'agent_relais', 'super_administrateur');
create type declaration_statut as enum ('active', 'correspondance', 'en_verification', 'restituee', 'expiree', 'archivee');
create type verification_niveau as enum ('faible', 'moyen', 'eleve');

-- ---------------------------------------------------------
-- PROFILES (miroir de auth.users)
-- ---------------------------------------------------------
create table profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  nom_affiche text,
  telephone text unique,
  telephone_verifie boolean default false,
  role user_role not null default 'utilisateur',
  ville text,
  commune text,
  avatar_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- ---------------------------------------------------------
-- CRÉATION AUTOMATIQUE DU PROFIL À L'INSCRIPTION
-- ---------------------------------------------------------
-- Sans ce déclencheur, la table "profiles" reste vide après une connexion
-- par e-mail : "auth.users" est gérée par Supabase, mais rien ne crée la
-- ligne correspondante dans "profiles". Cela provoque par exemple un
-- "UPDATE ... 0 ligne modifiée" quand on essaie de s'attribuer le rôle admin.
create or replace function handle_new_user()
returns trigger
language plpgsql
security definer
as $$
begin
  insert into public.profiles (id, nom_affiche, telephone, ville, commune)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'nom_affiche', split_part(new.email, '@', 1)),
    new.raw_user_meta_data->>'telephone',
    new.raw_user_meta_data->>'ville',
    new.raw_user_meta_data->>'commune'
  )
  on conflict (id) do update set
    nom_affiche = coalesce(excluded.nom_affiche, profiles.nom_affiche),
    telephone = coalesce(excluded.telephone, profiles.telephone),
    ville = coalesce(excluded.ville, profiles.ville),
    commune = coalesce(excluded.commune, profiles.commune);
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function handle_new_user();

-- ---------------------------------------------------------
-- OBJECT TYPES (référentiel)
-- ---------------------------------------------------------
create table object_types (
  id text primary key,          -- ex: 'cni', 'permis', 'bancaire'
  label text not null,
  necessite_verification_forte boolean default false
);

insert into object_types (id, label, necessite_verification_forte) values
  ('cni', 'Carte d''identité', true),
  ('permis', 'Permis de conduire', true),
  ('cmu', 'Carte CMU', true),
  ('passeport', 'Passeport', true),
  ('electeur', 'Carte d''électeur', true),
  ('professionnelle', 'Carte professionnelle', false),
  ('etudiant', 'Carte étudiant', false),
  ('bancaire', 'Carte bancaire', true),
  ('telephone', 'Téléphone', false),
  ('portefeuille', 'Portefeuille', false),
  ('cles', 'Clés', false),
  ('autre', 'Autre objet', false);

-- ---------------------------------------------------------
-- LOST REPORTS — Parcours A
-- ---------------------------------------------------------
create table lost_reports (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references profiles(id) on delete cascade,
  object_type_id text not null references object_types(id),
  description text,               -- description publique, sans données sensibles
  ville text not null,
  commune text,
  date_perte date not null,
  statut declaration_statut not null default 'active',
  -- éléments de vérification privés (jamais exposés en clair au trouveur)
  criteres_verification jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- ---------------------------------------------------------
-- FOUND REPORTS — Parcours B
-- ---------------------------------------------------------
create table found_reports (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references profiles(id) on delete cascade,
  object_type_id text not null references object_types(id),
  description text,
  ville text not null,
  commune text,
  date_trouvaille date not null,
  photo_url text,                  -- Supabase Storage, infos sensibles floutées/masquées en amont
  statut declaration_statut not null default 'active',
  consentement_publication boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- ---------------------------------------------------------
-- MATCHES — Parcours C (calculés par une Edge Function / job)
-- ---------------------------------------------------------
create table matches (
  id uuid primary key default uuid_generate_v4(),
  lost_report_id uuid not null references lost_reports(id) on delete cascade,
  found_report_id uuid not null references found_reports(id) on delete cascade,
  score numeric(5,2) not null,      -- 0 à 100
  details jsonb,                    -- critères ayant contribué au score (explicabilité)
  notifie boolean not null default false, -- évite de notifier deux fois la même correspondance
  masque boolean not null default false,  -- masquage par un administrateur (sans suppression)
  created_at timestamptz not null default now(),
  unique (lost_report_id, found_report_id)
);

-- ---------------------------------------------------------
-- VERIFICATION REQUESTS
-- ---------------------------------------------------------
create table verification_requests (
  id uuid primary key default uuid_generate_v4(),
  match_id uuid not null references matches(id) on delete cascade,
  demandeur_id uuid not null references profiles(id),
  niveau_confiance verification_niveau not null default 'faible',
  reponses jsonb,                   -- réponses du demandeur aux critères
  validee boolean,
  created_at timestamptz not null default now()
);

-- ---------------------------------------------------------
-- MESSAGES (messagerie interne sécurisée)
-- ---------------------------------------------------------
create table messages (
  id uuid primary key default uuid_generate_v4(),
  match_id uuid references matches(id) on delete cascade,
  expediteur_id uuid not null references profiles(id),
  destinataire_id uuid not null references profiles(id),
  contenu text not null,
  lu boolean default false,
  created_at timestamptz not null default now()
);

-- ---------------------------------------------------------
-- NOTIFICATIONS
-- ---------------------------------------------------------
create table notifications (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references profiles(id) on delete cascade,
  titre text not null,
  corps text,
  type text,                        -- 'correspondance' | 'message' | 'statut' | 'systeme'
  lu boolean default false,
  created_at timestamptz not null default now()
);

-- ---------------------------------------------------------
-- PARTNERS & PICKUP POINTS (créés avant restitution_requests, qui y fait référence)
-- ---------------------------------------------------------
create table partners (
  id uuid primary key default uuid_generate_v4(),
  nom text not null,
  contact_email text,
  contact_telephone text,
  actif boolean default true,
  created_at timestamptz not null default now()
);

create table pickup_points (
  id uuid primary key default uuid_generate_v4(),
  partner_id uuid references partners(id) on delete set null,
  nom text not null,
  ville text not null,
  commune text,
  adresse text,
  horaires text,
  latitude numeric(9,6),
  longitude numeric(9,6),
  actif boolean default true,
  created_at timestamptz not null default now()
);

-- ---------------------------------------------------------
-- RESTITUTION
-- ---------------------------------------------------------
create table restitution_requests (
  id uuid primary key default uuid_generate_v4(),
  match_id uuid not null references matches(id) on delete cascade,
  initiee_par uuid not null references profiles(id),
  pickup_point_id uuid references pickup_points(id),
  statut text default 'en_attente', -- 'en_attente' | 'confirmee' | 'annulee'
  created_at timestamptz not null default now()
);

create table restitutions (
  id uuid primary key default uuid_generate_v4(),
  restitution_request_id uuid not null references restitution_requests(id) on delete cascade,
  confirmee_par_proprietaire boolean default false,
  confirmee_par_trouveur boolean default false,
  date_restitution timestamptz,
  created_at timestamptz not null default now()
);

-- ---------------------------------------------------------
-- REPORTS (signalements) & FRAUD ALERTS
-- ---------------------------------------------------------
create table reports (
  id uuid primary key default uuid_generate_v4(),
  auteur_id uuid not null references profiles(id),
  cible_type text not null,          -- 'lost_report' | 'found_report' | 'user' | 'message'
  cible_id uuid,
  motif text not null,
  details text,
  statut text default 'ouvert',      -- 'ouvert' | 'en_cours' | 'clos'
  created_at timestamptz not null default now()
);

create table fraud_alerts (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid references profiles(id),
  raison text not null,
  score_risque numeric(5,2),
  created_at timestamptz not null default now()
);

-- ---------------------------------------------------------
-- AUDIT LOGS
-- ---------------------------------------------------------
create table audit_logs (
  id uuid primary key default uuid_generate_v4(),
  acteur_id uuid references profiles(id),
  action text not null,
  cible_type text,
  cible_id uuid,
  metadata jsonb,
  created_at timestamptz not null default now()
);

-- =========================================================
-- ROW LEVEL SECURITY
-- =========================================================
alter table profiles enable row level security;
alter table lost_reports enable row level security;
alter table found_reports enable row level security;
alter table matches enable row level security;
alter table verification_requests enable row level security;
alter table messages enable row level security;
alter table notifications enable row level security;
alter table restitution_requests enable row level security;
alter table restitutions enable row level security;
alter table reports enable row level security;
alter table fraud_alerts enable row level security;
alter table audit_logs enable row level security;

-- PROFILES : chacun lit/modifie son propre profil ; lecture publique limitée gérée via vue dédiée
create policy "profil_lecture_soi" on profiles for select using (auth.uid() = id);
create policy "profil_maj_soi" on profiles for update using (auth.uid() = id);

-- LOST REPORTS : le propriétaire gère sa déclaration ; description publique visible de tous les authentifiés
create policy "lost_reports_lecture" on lost_reports for select using (auth.role() = 'authenticated');
create policy "lost_reports_creation" on lost_reports for insert with check (auth.uid() = user_id);
create policy "lost_reports_maj" on lost_reports for update using (auth.uid() = user_id);
create policy "lost_reports_suppression" on lost_reports for delete using (auth.uid() = user_id);

-- FOUND REPORTS : idem, mais les champs sensibles doivent être filtrés côté application/Edge Function
create policy "found_reports_lecture" on found_reports for select using (auth.role() = 'authenticated');
create policy "found_reports_lecture_publique" on found_reports for select using (statut = 'active');
create policy "found_reports_creation" on found_reports for insert with check (auth.uid() = user_id);
create policy "found_reports_maj" on found_reports for update using (auth.uid() = user_id);
create policy "found_reports_suppression" on found_reports for delete using (auth.uid() = user_id);

-- MATCHES : visibles uniquement par les deux déclarants concernés
create policy "matches_lecture" on matches for select using (
  exists (select 1 from lost_reports lr where lr.id = lost_report_id and lr.user_id = auth.uid())
  or exists (select 1 from found_reports fr where fr.id = found_report_id and fr.user_id = auth.uid())
);

-- VERIFICATION REQUESTS : réservé au demandeur et aux modérateurs (via Edge Function côté serveur)
create policy "verif_lecture_demandeur" on verification_requests for select using (auth.uid() = demandeur_id);
create policy "verif_creation_demandeur" on verification_requests for insert with check (auth.uid() = demandeur_id);

-- MESSAGES : uniquement expéditeur/destinataire
create policy "messages_lecture" on messages for select using (auth.uid() = expediteur_id or auth.uid() = destinataire_id);
create policy "messages_creation" on messages for insert with check (auth.uid() = expediteur_id);
create policy "messages_maj_lu" on messages for update using (auth.uid() = destinataire_id);

-- NOTIFICATIONS : uniquement le destinataire
create policy "notifications_lecture" on notifications for select using (auth.uid() = user_id);
create policy "notifications_maj" on notifications for update using (auth.uid() = user_id);

-- RESTITUTIONS : visibles par les parties du match concerné
create policy "restitution_requests_lecture" on restitution_requests for select using (
  exists (
    select 1 from matches m
    join lost_reports lr on lr.id = m.lost_report_id
    join found_reports fr on fr.id = m.found_report_id
    where m.id = match_id and (lr.user_id = auth.uid() or fr.user_id = auth.uid())
  )
);

-- REPORTS : l'auteur peut créer et voir ses propres signalements ; modération gérée côté serveur (service role)
create policy "reports_creation" on reports for insert with check (auth.uid() = auteur_id);
create policy "reports_lecture_auteur" on reports for select using (auth.uid() = auteur_id);

-- FRAUD ALERTS & AUDIT LOGS : aucun accès direct côté client (réservé au rôle service, via Edge Functions)
-- (pas de policy select => bloqué pour les rôles anon/authenticated par défaut)

-- =========================================================
-- CONTENU DU SITE — géré depuis l'administration
-- =========================================================

-- Textes / réglages éditables (titre du hero, sous-titre, etc.)
create table site_settings (
  cle text primary key,          -- ex: 'hero_titre', 'hero_sous_titre'
  valeur text,
  updated_at timestamptz not null default now(),
  updated_by uuid references profiles(id)
);

insert into site_settings (cle, valeur) values
  ('hero_titre', 'Vous avez perdu un objet ?'),
  ('hero_titre_accent', 'Quelqu''un l''a peut-être retrouvé.'),
  ('hero_sous_titre', 'RETROUVA connecte les personnes qui perdent et celles qui trouvent des documents et objets importants — CNI, permis, cartes, téléphones, clés — partout en Côte d''Ivoire.'),
  ('hero_background_type', 'animation'),
  ('hero_video_url', ''),
  ('hero_backdrop_url', '');

-- Bannières publicitaires / informatives affichées sur le site
create table banners (
  id uuid primary key default uuid_generate_v4(),
  titre text not null,
  texte text,
  image_url text,
  lien_url text,
  position text not null default 'accueil', -- 'accueil' | 'resultats' | 'toutes_pages'
  actif boolean not null default true,
  date_debut date,
  date_fin date,
  created_by uuid references profiles(id),
  created_at timestamptz not null default now()
);

-- Pop-up publicitaires / informationnels (affichés une fois par visite)
create table popups (
  id uuid primary key default uuid_generate_v4(),
  titre text not null,
  texte text,
  image_url text,
  lien_url text,
  lien_label text default 'En savoir plus',
  actif boolean not null default true,
  date_debut date,
  date_fin date,
  created_by uuid references profiles(id),
  created_at timestamptz not null default now()
);

-- Événements / séances organisés par l'équipe (ex : journées de restitution)
create table events (
  id uuid primary key default uuid_generate_v4(),
  titre text not null,
  description text,
  lieu text,
  date_evenement timestamptz not null,
  image_url text,
  actif boolean not null default true,
  created_by uuid references profiles(id),
  created_at timestamptz not null default now()
);

-- ---------------------------------------------------------
-- RLS — CONTENU DU SITE
-- ---------------------------------------------------------
alter table site_settings enable row level security;
alter table banners enable row level security;
alter table popups enable row level security;
alter table events enable row level security;

-- Fonction utilitaire : l'utilisateur connecté est-il administrateur ?
create or replace function is_admin()
returns boolean
language sql
security definer
stable
as $$
  select exists (
    select 1 from profiles
    where id = auth.uid()
    and role in ('administrateur', 'super_administrateur')
  );
$$;

-- Lecture publique du contenu actif, écriture réservée aux administrateurs
create policy "site_settings_lecture" on site_settings for select using (true);
create policy "site_settings_ecriture" on site_settings for all using (is_admin()) with check (is_admin());

create policy "banners_lecture" on banners for select using (actif = true or is_admin());
create policy "banners_ecriture" on banners for all using (is_admin()) with check (is_admin());

create policy "popups_lecture" on popups for select using (actif = true or is_admin());
create policy "popups_ecriture" on popups for all using (is_admin()) with check (is_admin());

create policy "events_lecture" on events for select using (actif = true or is_admin());
create policy "events_ecriture" on events for all using (is_admin()) with check (is_admin());

-- Les administrateurs peuvent aussi lire/modérer toutes les déclarations et tous les profils
create policy "admin_lecture_profiles" on profiles for select using (is_admin());
create policy "admin_maj_profiles" on profiles for update using (is_admin()) with check (is_admin());
create policy "admin_maj_lost_reports" on lost_reports for update using (is_admin());
create policy "admin_maj_found_reports" on found_reports for update using (is_admin());
create policy "admin_lecture_reports" on reports for select using (is_admin());
create policy "admin_maj_reports" on reports for update using (is_admin());
create policy "admin_suppression_lost_reports" on lost_reports for delete using (is_admin());
create policy "admin_suppression_found_reports" on found_reports for delete using (is_admin());
create policy "admin_lecture_matches" on matches for select using (is_admin());
create policy "admin_maj_matches" on matches for update using (is_admin());
create policy "admin_suppression_matches" on matches for delete using (is_admin());
create policy "admin_suppression_reports" on reports for delete using (is_admin());

-- =========================================================
-- MOTEUR DE CORRESPONDANCE AUTOMATIQUE
-- =========================================================
-- Calcule un score (0 à 100) entre déclarations perdues et trouvées :
-- même ville obligatoire (40 pts), même commune (+20), proximité de dates
-- (jusqu'à +40). Se déclenche automatiquement à chaque nouvelle déclaration
-- et notifie le propriétaire quand le score atteint 70.

create or replace function calculer_matches_pour_perdu(p_lost_report_id uuid)
returns void
language plpgsql
security definer
as $$
declare
  lr lost_reports%rowtype;
begin
  select * into lr from lost_reports where id = p_lost_report_id;
  if lr.id is null then return; end if;

  insert into matches (lost_report_id, found_report_id, score, details)
  select
    lr.id,
    fr.id,
    least(100,
      40 * (fr.ville = lr.ville)::int
      + 20 * (fr.commune is not null and lr.commune is not null and fr.commune = lr.commune)::int
      + case
          when abs(fr.date_trouvaille - lr.date_perte) <= 3  then 40
          when abs(fr.date_trouvaille - lr.date_perte) <= 7  then 30
          when abs(fr.date_trouvaille - lr.date_perte) <= 14 then 20
          when abs(fr.date_trouvaille - lr.date_perte) <= 30 then 10
          else 0
        end
    ) as score,
    jsonb_build_object(
      'type_identique', true,
      'ville_identique', fr.ville = lr.ville,
      'commune_identique', fr.commune is not null and lr.commune is not null and fr.commune = lr.commune,
      'ecart_jours', abs(fr.date_trouvaille - lr.date_perte)
    ) as details
  from found_reports fr
  where fr.object_type_id = lr.object_type_id
    and fr.statut = 'active'
    and fr.ville = lr.ville
    and abs(fr.date_trouvaille - lr.date_perte) <= 60
  on conflict (lost_report_id, found_report_id)
  do update set score = excluded.score, details = excluded.details;

  update lost_reports set statut = 'correspondance'
  where id = lr.id and statut = 'active'
    and exists (select 1 from matches where lost_report_id = lr.id and score >= 70);

  insert into notifications (user_id, titre, corps, type)
  select lr.user_id,
    'Correspondance trouvée',
    'Une déclaration pourrait correspondre à votre objet perdu (score ' || m.score || '%).',
    'correspondance'
  from matches m
  where m.lost_report_id = lr.id and m.score >= 70 and m.notifie = false;

  update matches set notifie = true
  where lost_report_id = lr.id and score >= 70 and notifie = false;
end;
$$;

create or replace function calculer_matches_pour_trouve(p_found_report_id uuid)
returns void
language plpgsql
security definer
as $$
declare
  fr found_reports%rowtype;
begin
  select * into fr from found_reports where id = p_found_report_id;
  if fr.id is null then return; end if;

  insert into matches (lost_report_id, found_report_id, score, details)
  select
    lr.id,
    fr.id,
    least(100,
      40 * (fr.ville = lr.ville)::int
      + 20 * (fr.commune is not null and lr.commune is not null and fr.commune = lr.commune)::int
      + case
          when abs(fr.date_trouvaille - lr.date_perte) <= 3  then 40
          when abs(fr.date_trouvaille - lr.date_perte) <= 7  then 30
          when abs(fr.date_trouvaille - lr.date_perte) <= 14 then 20
          when abs(fr.date_trouvaille - lr.date_perte) <= 30 then 10
          else 0
        end
    ) as score,
    jsonb_build_object(
      'type_identique', true,
      'ville_identique', fr.ville = lr.ville,
      'commune_identique', fr.commune is not null and lr.commune is not null and fr.commune = lr.commune,
      'ecart_jours', abs(fr.date_trouvaille - lr.date_perte)
    ) as details
  from lost_reports lr
  where lr.object_type_id = fr.object_type_id
    and lr.statut in ('active', 'correspondance')
    and lr.ville = fr.ville
    and abs(fr.date_trouvaille - lr.date_perte) <= 60
  on conflict (lost_report_id, found_report_id)
  do update set score = excluded.score, details = excluded.details;

  update lost_reports lr set statut = 'correspondance'
  from matches m
  where m.found_report_id = fr.id and m.lost_report_id = lr.id
    and lr.statut = 'active' and m.score >= 70;

  insert into notifications (user_id, titre, corps, type)
  select lr.user_id,
    'Correspondance trouvée',
    'Une déclaration pourrait correspondre à votre objet perdu (score ' || m.score || '%).',
    'correspondance'
  from matches m
  join lost_reports lr on lr.id = m.lost_report_id
  where m.found_report_id = fr.id and m.score >= 70 and m.notifie = false;

  update matches set notifie = true
  where found_report_id = fr.id and score >= 70 and notifie = false;
end;
$$;

create or replace function trg_matching_apres_perte()
returns trigger language plpgsql as $$
begin
  perform calculer_matches_pour_perdu(new.id);
  return new;
end;
$$;

create trigger after_lost_report_insert
  after insert on lost_reports
  for each row execute function trg_matching_apres_perte();

create or replace function trg_matching_apres_trouve()
returns trigger language plpgsql as $$
begin
  perform calculer_matches_pour_trouve(new.id);
  return new;
end;
$$;

create trigger after_found_report_insert
  after insert on found_reports
  for each row execute function trg_matching_apres_trouve();

-- =========================================================
-- POLITIQUES D'ACCÈS AU STORAGE
-- =========================================================
-- IMPORTANT : rendre un bucket "Public" (option du dashboard) ne contrôle
-- que la LECTURE. Sans ces politiques, personne ne peut envoyer de fichier,
-- même un administrateur. Créez d'abord les buckets 'site-media' et
-- 'objets-trouves' dans Dashboard Supabase > Storage avant d'exécuter ceci.

create policy "site_media_lecture_publique" on storage.objects
  for select using (bucket_id = 'site-media');

create policy "site_media_ecriture_admin" on storage.objects
  for insert with check (bucket_id = 'site-media' and public.is_admin());

create policy "site_media_maj_admin" on storage.objects
  for update using (bucket_id = 'site-media' and public.is_admin());

create policy "site_media_suppression_admin" on storage.objects
  for delete using (bucket_id = 'site-media' and public.is_admin());

create policy "objets_trouves_lecture_publique" on storage.objects
  for select using (bucket_id = 'objets-trouves');

create policy "objets_trouves_ecriture_auth" on storage.objects
  for insert with check (bucket_id = 'objets-trouves' and auth.role() = 'authenticated');

-- =========================================================
-- STATISTIQUES PUBLIQUES (page d'accueil)
-- =========================================================
-- Compteurs agrégés uniquement, jamais de ligne individuelle ni de donnée
-- personnelle — utilisable par les visiteurs non connectés.
create or replace function public_stats()
returns json
language sql
security definer
stable
as $$
  select json_build_object(
    'trouves', (select count(*) from found_reports where statut = 'active'),
    'perdus', (select count(*) from lost_reports where statut in ('active', 'correspondance')),
    'utilisateurs', (select count(*) from profiles),
    'villes', (select count(distinct ville) from found_reports)
  );
$$;

grant execute on function public_stats() to anon, authenticated;

create or replace function public_carte_data()
returns table(ville text, perdus bigint, trouves bigint)
language sql
security definer
stable
as $$
  select
    coalesce(l.ville, f.ville) as ville,
    coalesce(l.cnt, 0) as perdus,
    coalesce(f.cnt, 0) as trouves
  from
    (select ville, count(*) cnt from lost_reports where statut in ('active','correspondance') group by ville) l
  full outer join
    (select ville, count(*) cnt from found_reports where statut = 'active' group by ville) f
  on l.ville = f.ville;
$$;

grant execute on function public_carte_data() to anon, authenticated;

-- =========================================================
-- INTRODUCTION AU PREMIER LANCEMENT
-- =========================================================
create table onboarding_slides (
  id uuid primary key default uuid_generate_v4(),
  titre text not null,
  description text,
  icone text not null default 'card',
  ordre integer not null default 0,
  actif boolean not null default true,
  created_by uuid references profiles(id),
  created_at timestamptz not null default now()
);

alter table onboarding_slides enable row level security;

create policy "onboarding_lecture" on onboarding_slides for select using (actif = true or is_admin());
create policy "onboarding_ecriture" on onboarding_slides for all using (is_admin()) with check (is_admin());

insert into onboarding_slides (titre, description, icone, ordre) values
  ('Bienvenue sur RETROUVA', 'La plateforme ivoirienne qui aide à retrouver, connecter et restituer les objets et documents perdus.', 'pin', 1),
  ('Déclarez une perte ou une trouvaille', 'Décrivez l''objet en quelques informations. Aucune donnée sensible n''est jamais publiée.', 'card', 2),
  ('Correspondance automatique', 'Notre moteur compare vos déclarations et vous notifie dès qu''une correspondance sérieuse est trouvée.', 'search', 3),
  ('Vérification et restitution sécurisées', 'Échangez via notre messagerie interne pour vérifier l''identité avant toute remise.', 'shield', 4);

-- =========================================================
-- INDEX UTILES
-- =========================================================
create index idx_lost_reports_type_ville on lost_reports (object_type_id, ville, statut);
create index idx_found_reports_type_ville on found_reports (object_type_id, ville, statut);
create index idx_matches_lost on matches (lost_report_id);
create index idx_matches_found on matches (found_report_id);
create index idx_messages_match on messages (match_id);
create index idx_notifications_user on notifications (user_id, lu);
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
-- =========================================================
-- RETROUVA — Migration 21 : chat de support (bouton flottant),
-- numéro WhatsApp support, et vrais numéros de don
-- =========================================================
-- Additive uniquement, sans danger sur une base à jour jusqu'à la
-- migration 20.

-- ---------------------------------------------------------
-- 1) CHAT DE SUPPORT TECHNIQUE
-- ---------------------------------------------------------
-- Une conversation par "visiteur" : son id de profil s'il est connecté,
-- sinon un identifiant anonyme généré et gardé dans son navigateur
-- (localStorage). Gérée depuis /admin/support.
create table if not exists support_messages (
  id uuid primary key default uuid_generate_v4(),
  conversation_id text not null,
  auteur text not null default 'utilisateur', -- 'utilisateur' | 'admin'
  nom_visiteur text,
  contenu text not null,
  lu boolean not null default false,
  created_at timestamptz not null default now()
);

alter table support_messages enable row level security;

-- Chacun peut écrire dans le support (connecté ou non) ; la lecture des
-- messages ne remonte que par conversation précise (le visiteur ne
-- connaît que la sienne côté client) ou intégralement pour l'admin.
create policy "support_messages_creation" on support_messages for insert with check (true);
create policy "support_messages_lecture" on support_messages for select using (true);
create policy "support_messages_maj_admin" on support_messages for update using (is_admin());

create index if not exists idx_support_messages_conversation on support_messages (conversation_id, created_at);

-- ---------------------------------------------------------
-- 2) NUMÉRO WHATSAPP DU SUPPORT (bouton flottant)
-- ---------------------------------------------------------
insert into site_settings (cle, valeur) values
  ('whatsapp_support_numero', '2250797676545')
on conflict (cle) do nothing;

-- ---------------------------------------------------------
-- 3) VRAIS NUMÉROS DE DON (remplacent les numéros d'exemple)
-- ---------------------------------------------------------
-- Ne touche que les 2 méthodes concernées, sans écraser une
-- modification déjà faite manuellement par l'admin dans /admin/dons.
update payment_methods set numero = '+225 07 97 67 65 45'
  where nom = 'Orange Money' and numero = '+225 07 00 00 00 00';
update payment_methods set numero = '+225 05 46 22 97 78'
  where nom = 'MTN Mobile Money' and numero = '+225 05 00 00 00 00';
update payment_methods set numero = '+225 07 97 67 65 45'
  where nom = 'Wave' and numero = '+225 01 00 00 00 00';
