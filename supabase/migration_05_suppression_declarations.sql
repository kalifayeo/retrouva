-- =========================================================
-- RETROUVA — Migration 05 : autoriser la suppression de ses propres
-- déclarations (perdu / trouvé), utile pour nettoyer les doublons créés
-- pendant les tests. La suppression d'une déclaration supprime aussi
-- automatiquement ses correspondances (contrainte ON DELETE CASCADE déjà
-- en place sur la table "matches").
-- =========================================================

create policy "lost_reports_suppression" on lost_reports for delete using (auth.uid() = user_id);
create policy "found_reports_suppression" on found_reports for delete using (auth.uid() = user_id);
