-- =========================================================
-- RETROUVA — Migration 19 : édition de profil (page /profil)
-- =========================================================
-- Contexte : la page /profil ne faisait jusqu'ici que rediriger vers
-- d'autres pages, aucune modification n'était possible. On ajoute la
-- possibilité de modifier nom/téléphone/ville/commune et une photo de
-- profil. Cette migration ne touche à aucune table existante, elle :
--   1) crée le bucket de stockage "avatars" (même principe que le
--      bucket "objets-trouves" déjà en place, migration_08) ;
--   2) verrouille la colonne `role` de `profiles` contre toute
--      auto-promotion, un point resté ouvert depuis la création de la
--      table (policy "profil_maj_soi" sans restriction de colonnes) et
--      qui devient exploitable dès qu'un formulaire d'édition existe
--      côté client. Toutes les autres colonnes restent modifiables par
--      leur propriétaire, sans changement de comportement.
-- =========================================================

-- ---------------------------------------------------------
-- 1) Bucket "avatars" — lecture publique (photos affichées sur les
--    déclarations et dans la messagerie), écriture réservée à chaque
--    utilisateur dans SON PROPRE dossier (préfixe = son user id, comme
--    pour "objets-trouves").
-- ---------------------------------------------------------
insert into storage.buckets (id, name, public)
values ('avatars', 'avatars', true)
on conflict (id) do nothing;

drop policy if exists "avatars_lecture_publique" on storage.objects;
create policy "avatars_lecture_publique" on storage.objects
  for select using (bucket_id = 'avatars');

drop policy if exists "avatars_ecriture_soi" on storage.objects;
create policy "avatars_ecriture_soi" on storage.objects
  for insert with check (
    bucket_id = 'avatars'
    and auth.uid()::text = (storage.foldername(name))[1]
  );

drop policy if exists "avatars_maj_soi" on storage.objects;
create policy "avatars_maj_soi" on storage.objects
  for update using (
    bucket_id = 'avatars'
    and auth.uid()::text = (storage.foldername(name))[1]
  );

-- ---------------------------------------------------------
-- 2) Verrou anti auto-promotion : un utilisateur qui modifie son propre
--    profil ne peut jamais changer son `role`, sauf s'il est déjà
--    administrateur (cas légitime : gestion des rôles depuis /admin).
-- ---------------------------------------------------------
create or replace function proteger_role_profil()
returns trigger
language plpgsql
security definer
as $$
begin
  if new.role is distinct from old.role and not is_admin() then
    new.role := old.role;
  end if;
  return new;
end;
$$;

drop trigger if exists trg_proteger_role_profil on profiles;
create trigger trg_proteger_role_profil
  before update on profiles
  for each row
  execute function proteger_role_profil();
