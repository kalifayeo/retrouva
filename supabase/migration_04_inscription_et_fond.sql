-- =========================================================
-- RETROUVA — Migration 04 : inscription complète + fond d'accueil gérable
-- =========================================================
-- À exécuter une fois dans Supabase > SQL Editor (après migration_03).

-- ---------------------------------------------------------
-- 1) Le profil récupère maintenant les infos saisies à l'inscription
--    (nom, téléphone, ville, commune), transmises via
--    supabase.auth.signUp({ options: { data: {...} } })
-- ---------------------------------------------------------
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

-- ---------------------------------------------------------
-- 2) Réglages du fond animé/vidéo de la page d'accueil,
--    modifiables depuis /admin/contenu (aucun fichier à toucher manuellement)
-- ---------------------------------------------------------
insert into site_settings (cle, valeur) values
  ('hero_background_type', 'animation'),  -- 'animation' | 'video'
  ('hero_video_url', '')
on conflict (cle) do nothing;
