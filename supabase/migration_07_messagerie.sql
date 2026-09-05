-- =========================================================
-- RETROUVA — Migration 07 : politique manquante pour marquer les
-- messages comme lus (nécessaire pour la vraie messagerie).
-- =========================================================

create policy "messages_maj_lu" on messages for update using (auth.uid() = destinataire_id);
