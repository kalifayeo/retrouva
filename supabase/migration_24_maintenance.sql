-- =========================================================
-- MIGRATION 24 — MODE MAINTENANCE
-- =========================================================
-- Ajoute deux réglages dans la table "site_settings" (déjà en place et déjà
-- lisible publiquement / modifiable par les admins, voir schema.sql) :
--   - 'maintenance_mode'    : 'on' ou 'off'
--   - 'maintenance_message' : message optionnel affiché sur /maintenance
--
-- Aucune nouvelle policy n'est nécessaire : "site_settings_lecture" (select
-- using true) et "site_settings_ecriture" (is_admin()) couvrent déjà ces
-- deux nouvelles clés. Basculez le mode maintenance depuis
-- /admin/contenu → section "Mode maintenance", pas besoin de SQL au
-- quotidien : ce script sert uniquement à créer les deux lignes une fois.

insert into site_settings (cle, valeur) values
  ('maintenance_mode', 'off'),
  ('maintenance_message', '')
on conflict (cle) do nothing;
