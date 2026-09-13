-- =========================================================
-- RETROUVA — Migration 09 : contrôle admin complet
-- =========================================================
-- Permet à l'administrateur de voir, modifier, supprimer et masquer
-- n'importe quelle déclaration, correspondance ou signalement.

-- ---------------------------------------------------------
-- 1) Masquage des correspondances (sans les supprimer)
-- ---------------------------------------------------------
alter table matches add column if not exists masque boolean not null default false;

-- ---------------------------------------------------------
-- 2) Droits complets pour les administrateurs
-- ---------------------------------------------------------
-- Déclarations : suppression en plus de la modification déjà accordée
create policy "admin_suppression_lost_reports" on lost_reports for delete using (public.is_admin());
create policy "admin_suppression_found_reports" on found_reports for delete using (public.is_admin());

-- Correspondances : lecture, modification (masquage) et suppression
create policy "admin_lecture_matches" on matches for select using (public.is_admin());
create policy "admin_maj_matches" on matches for update using (public.is_admin());
create policy "admin_suppression_matches" on matches for delete using (public.is_admin());

-- Signalements : suppression (en plus de la modification déjà accordée)
create policy "admin_suppression_reports" on reports for delete using (public.is_admin());
