-- =========================================================
-- RETROUVA — Migration 18 : sécurise partners/pickup_points (RLS manquante)
-- + ajoute une fréquence d'affichage programmable aux pop-up.
-- =========================================================
-- Déjà exécutée avec succès dans Supabase > SQL Editor (documentée ici
-- après coup pour garder l'historique complet et reproductible sur une
-- autre base si besoin).
-- =========================================================

-- ---------------------------------------------------------
-- 1) partners / pickup_points existaient sans RLS ni policy : n'importe
--    quel client (anon ou authentifié) pouvait donc les lire/modifier/
--    supprimer directement. On applique le même principe que le reste
--    du CMS : lecture publique du contenu actif, écriture réservée aux
--    administrateurs via is_admin().
-- ---------------------------------------------------------
alter table partners enable row level security;
alter table pickup_points enable row level security;

drop policy if exists "partners_lecture" on partners;
drop policy if exists "partners_ecriture" on partners;
create policy "partners_lecture" on partners for select using (actif = true or is_admin());
create policy "partners_ecriture" on partners for all using (is_admin()) with check (is_admin());

drop policy if exists "pickup_points_lecture" on pickup_points;
drop policy if exists "pickup_points_ecriture" on pickup_points;
create policy "pickup_points_lecture" on pickup_points for select using (actif = true or is_admin());
create policy "pickup_points_ecriture" on pickup_points for all using (is_admin()) with check (is_admin());

-- ---------------------------------------------------------
-- 2) Pop-up : fréquence d'affichage programmable par l'administrateur.
--    'session'     -> une fois par visite (comportement actuel, inchangé par défaut)
--    'quotidien'   -> une fois par 24h
--    'intervalle'  -> se répète toutes les `intervalle_minutes` tant que le site est ouvert
--    'chaque_page' -> réaffiché à chaque changement de page
-- ---------------------------------------------------------
alter table popups add column if not exists frequence text not null default 'session';
alter table popups add column if not exists intervalle_minutes integer default 30;

do $$
begin
  if not exists (
    select 1 from pg_constraint where conname = 'popups_frequence_check'
  ) then
    alter table popups add constraint popups_frequence_check
      check (frequence in ('session', 'quotidien', 'intervalle', 'chaque_page'));
  end if;
end $$;
