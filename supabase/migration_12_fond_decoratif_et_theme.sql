-- =========================================================
-- RETROUVA — Migration 12 : image de fond décorative de l'accueil
-- =========================================================
insert into site_settings (cle, valeur) values
  ('hero_backdrop_url', '')
on conflict (cle) do nothing;
