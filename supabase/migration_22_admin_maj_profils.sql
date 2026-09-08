-- =========================================================
-- RETROUVA — Migration 22 : les admins peuvent enfin modifier
-- le profil (rôle) des autres comptes
-- =========================================================
-- Contexte : /admin/utilisateurs permet de changer le rôle d'un compte
-- (ex. passer un "utilisateur" en "super_administrateur"), mais aucune
-- policy RLS n'autorisait un administrateur à modifier la ligne
-- `profiles` d'un AUTRE compte : seule la policy "profil_maj_soi"
-- existait (auth.uid() = id), donc la mise à jour ne touchait aucune
-- ligne — Supabase ne renvoyait pas d'erreur, ce qui donnait
-- l'impression trompeuse que le changement avait réussi alors qu'il
-- n'était jamais enregistré en base. Le trigger anti auto-promotion
-- (migration_19) autorise déjà correctement les admins à changer un
-- rôle ; il ne manquait que cette policy.
-- =========================================================

drop policy if exists "admin_maj_profiles" on profiles;
create policy "admin_maj_profiles" on profiles
  for update using (is_admin()) with check (is_admin());
