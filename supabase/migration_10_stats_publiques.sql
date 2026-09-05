-- =========================================================
-- RETROUVA — Migration 10 : statistiques et fil d'actualité publics
-- =========================================================
-- Permet d'afficher sur la page d'accueil de vraies statistiques et les
-- dernières déclarations trouvées, visibles même sans connexion — comme sur
-- les sites de référence du même type. Aucune donnée personnelle n'est
-- exposée : uniquement des compteurs globaux et les champs déjà publics
-- (type d'objet, ville, date).

-- Fonction sécurisée : ne renvoie que des compteurs agrégés, jamais de
-- lignes individuelles ni d'information sur un utilisateur précis.
create or replace function public_stats()
returns json
language sql
security definer
stable
as $$
  select json_build_object(
    'trouves', (select count(*) from found_reports where statut = 'active'),
    'perdus', (select count(*) from lost_reports where statut in ('active', 'correspondance')),
    'utilisateurs', (select count(*) from profiles),
    'villes', (select count(distinct ville) from found_reports)
  );
$$;

grant execute on function public_stats() to anon, authenticated;

-- Lecture publique des déclarations trouvées actives (champs déjà
-- non sensibles : type, ville, commune, date), pour le fil "trouvés
-- récemment" affiché à tous les visiteurs.
create policy "found_reports_lecture_publique" on found_reports
  for select using (statut = 'active');
