-- =========================================================
-- RETROUVA — Migration 08 : politiques d'accès au Storage
-- =========================================================
-- ÉTAPE MANQUANTE JUSQU'ICI : rendre un bucket "Public" ne contrôle que la
-- LECTURE des fichiers. Sans politiques explicites sur storage.objects,
-- personne — pas même un administrateur — ne peut envoyer de fichier
-- ("new row violates row-level security policy"). Ce script corrige ça
-- pour les deux buckets utilisés par RETROUVA.

-- ---------------------------------------------------------
-- site-media (bannières, pop-up, événements — géré depuis l'admin)
-- Lecture publique, écriture réservée aux administrateurs.
-- ---------------------------------------------------------
create policy "site_media_lecture_publique" on storage.objects
  for select using (bucket_id = 'site-media');

create policy "site_media_ecriture_admin" on storage.objects
  for insert with check (bucket_id = 'site-media' and public.is_admin());

create policy "site_media_maj_admin" on storage.objects
  for update using (bucket_id = 'site-media' and public.is_admin());

create policy "site_media_suppression_admin" on storage.objects
  for delete using (bucket_id = 'site-media' and public.is_admin());

-- ---------------------------------------------------------
-- objets-trouves (photos ajoutées par n'importe quel utilisateur
-- connecté sur le formulaire "J'ai trouvé un objet")
-- Lecture publique, écriture pour tout utilisateur connecté.
-- ---------------------------------------------------------
create policy "objets_trouves_lecture_publique" on storage.objects
  for select using (bucket_id = 'objets-trouves');

create policy "objets_trouves_ecriture_auth" on storage.objects
  for insert with check (bucket_id = 'objets-trouves' and auth.role() = 'authenticated');
