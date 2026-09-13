-- =========================================================
-- MIGRATION 26 — "NOTRE IMPACT" DOIT REFLÉTER LES OBJETS RESTITUÉS
-- =========================================================
-- Problème constaté : la section "Notre impact" de l'accueil (compteur
-- "Objets trouvés" et fil "Activité récente") ne prenait en compte QUE les
-- déclarations au statut 'active'. Or, dès qu'un objet trouvé est remis à
-- son propriétaire, son statut passe à 'restituee' (voir
-- migration_15_verification_restitution.sql) — il disparaissait alors
-- complètement des statistiques et du fil public, alors même que c'est
-- justement ce type de succès que la page doit mettre en avant.
--
-- Cette migration remplace (CREATE OR REPLACE, donc sans risque si vous
-- n'avez pas encore exécuté migration_25) les deux fonctions concernées :
--
-- 1) public_stats() : "Objets trouvés" compte désormais les objets trouvés
--    actifs ET déjà restitués (avant : actifs uniquement).
-- 2) public_activity_feed() : inclut aussi les déclarations restituées
--    (pertes récupérées ET trouvailles remises), avec le statut renvoyé en
--    plus pour que l'accueil puisse afficher le bon libellé ("remis à son
--    propriétaire" plutôt que "retrouvé").
--
-- À exécuter dans Supabase → SQL Editor → Run (sur une base existante ; un
-- nouveau projet qui exécute schema.sql pour la première fois n'a pas besoin
-- de cette étape séparée si schema.sql a été mis à jour en conséquence).

create or replace function public_activity_feed(p_limit int default 8)
returns table (
  id uuid,
  genre text,
  statut declaration_statut,
  object_type_id text,
  ville text,
  commune text,
  created_at timestamptz
)
language sql
security definer
stable
as $$
  select id, 'perdu' as genre, statut, object_type_id, ville, commune, created_at
  from lost_reports
  where statut in ('active', 'correspondance', 'en_verification', 'restituee')
  union all
  select id, 'trouve' as genre, statut, object_type_id, ville, commune, created_at
  from found_reports
  where statut in ('active', 'restituee')
  order by created_at desc
  limit greatest(p_limit, 1)
$$;

grant execute on function public_activity_feed(int) to anon, authenticated;

create or replace function public_stats()
returns json
language sql
security definer
stable
as $$
  select json_build_object(
    'trouves', (select count(*) from found_reports where statut in ('active', 'restituee')),
    'perdus', (select count(*) from lost_reports where statut in ('active', 'correspondance', 'en_verification')),
    'utilisateurs', (select count(*) from profiles),
    'villes', (select count(distinct ville) from found_reports),
    'restitutions', (select count(*) from lost_reports where statut = 'restituee')
  );
$$;

grant execute on function public_stats() to anon, authenticated;
