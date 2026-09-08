-- =========================================================
-- RETROUVA — Migration 02 : correctif profils + module admin/CMS
-- =========================================================
-- À exécuter UNE SEULE FOIS dans Supabase > SQL Editor, si vous avez déjà
-- exécuté schema.sql une première fois (sinon utilisez schema.sql seul,
-- il contient déjà tout ce fichier).
-- =========================================================

-- ---------------------------------------------------------
-- 1) Déclencheur : crée automatiquement un profil à chaque inscription
-- ---------------------------------------------------------
create or replace function handle_new_user()
returns trigger
language plpgsql
security definer
as $$
begin
  insert into public.profiles (id, nom_affiche)
  values (new.id, split_part(new.email, '@', 1))
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function handle_new_user();

-- ---------------------------------------------------------
-- 2) Rattrapage : crée les profils manquants pour les comptes déjà inscrits
--    (corrige votre cas : le compte existait dans auth.users mais pas dans
--    profiles, d'où le "0 ligne modifiée" sur votre précédente commande).
-- ---------------------------------------------------------
insert into public.profiles (id, nom_affiche)
select u.id, split_part(u.email, '@', 1)
from auth.users u
left join public.profiles p on p.id = u.id
where p.id is null;

-- ---------------------------------------------------------
-- 3) Vous attribuer le rôle super administrateur
--    (remplacez l'e-mail si besoin — celui-ci correspond à votre compte)
-- ---------------------------------------------------------
update public.profiles set role = 'super_administrateur'
where id = (select id from auth.users where email = 'kalifayeo11@gmail.com');

-- ---------------------------------------------------------
-- 4) Module CMS — contenu du site, bannières, pop-up, événements
-- ---------------------------------------------------------
create table if not exists site_settings (
  cle text primary key,
  valeur text,
  updated_at timestamptz not null default now(),
  updated_by uuid references profiles(id)
);

insert into site_settings (cle, valeur) values
  ('hero_titre', 'Vous avez perdu un objet ?'),
  ('hero_titre_accent', 'Quelqu''un l''a peut-être retrouvé.'),
  ('hero_sous_titre', 'RETROUVA connecte les personnes qui perdent et celles qui trouvent des documents et objets importants — CNI, permis, cartes, téléphones, clés — partout en Côte d''Ivoire.')
on conflict (cle) do nothing;

create table if not exists banners (
  id uuid primary key default uuid_generate_v4(),
  titre text not null,
  texte text,
  image_url text,
  lien_url text,
  position text not null default 'accueil',
  actif boolean not null default true,
  date_debut date,
  date_fin date,
  created_by uuid references profiles(id),
  created_at timestamptz not null default now()
);

create table if not exists popups (
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

create table if not exists events (
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

alter table site_settings enable row level security;
alter table banners enable row level security;
alter table popups enable row level security;
alter table events enable row level security;

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

drop policy if exists "site_settings_lecture" on site_settings;
drop policy if exists "site_settings_ecriture" on site_settings;
create policy "site_settings_lecture" on site_settings for select using (true);
create policy "site_settings_ecriture" on site_settings for all using (is_admin()) with check (is_admin());

drop policy if exists "banners_lecture" on banners;
drop policy if exists "banners_ecriture" on banners;
create policy "banners_lecture" on banners for select using (actif = true or is_admin());
create policy "banners_ecriture" on banners for all using (is_admin()) with check (is_admin());

drop policy if exists "popups_lecture" on popups;
drop policy if exists "popups_ecriture" on popups;
create policy "popups_lecture" on popups for select using (actif = true or is_admin());
create policy "popups_ecriture" on popups for all using (is_admin()) with check (is_admin());

drop policy if exists "events_lecture" on events;
drop policy if exists "events_ecriture" on events;
create policy "events_lecture" on events for select using (actif = true or is_admin());
create policy "events_ecriture" on events for all using (is_admin()) with check (is_admin());

drop policy if exists "admin_lecture_profiles" on profiles;
drop policy if exists "admin_maj_lost_reports" on lost_reports;
drop policy if exists "admin_maj_found_reports" on found_reports;
drop policy if exists "admin_lecture_reports" on reports;
drop policy if exists "admin_maj_reports" on reports;
create policy "admin_lecture_profiles" on profiles for select using (is_admin());
create policy "admin_maj_lost_reports" on lost_reports for update using (is_admin());
create policy "admin_maj_found_reports" on found_reports for update using (is_admin());
create policy "admin_lecture_reports" on reports for select using (is_admin());
create policy "admin_maj_reports" on reports for update using (is_admin());

-- ---------------------------------------------------------
-- 5) Vérification finale — devrait afficher votre rôle admin
-- ---------------------------------------------------------
select id, nom_affiche, role from profiles
where id = (select id from auth.users where email = 'kalifayeo11@gmail.com');
