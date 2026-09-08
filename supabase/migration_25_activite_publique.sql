-- =========================================================
-- MIGRATION 25 — FLUX D'ACTIVITÉ PUBLIC & STATISTIQUE RESTITUTIONS
-- =========================================================
-- Objectif : la page d'accueil doit pouvoir afficher, même à un visiteur non
-- connecté, un fil "Activité récente" mélangeant pertes ET trouvailles
-- déclarées sur toute la plateforme — pas seulement les objets trouvés
-- comme avant.
--
-- Problème : "lost_reports" n'est lisible que par les utilisateurs connectés
-- (policy "lost_reports_lecture"), donc un visiteur anonyme ne peut pas la
-- consulter directement, même partiellement.
--
-- Solution : une fonction SECURITY DEFINER, sur le même principe que
-- public_stats() (déjà en place), qui ne renvoie QUE les champs déjà
-- publics par ailleurs pour les objets trouvés (type d'objet, ville,
-- commune, date) — jamais de description, de user_id ou de critère de
-- vérification. Aucune information nouvelle n'est donc exposée : on
-- applique simplement aux pertes le même niveau de visibilité déjà
-- accordé aux trouvailles.

create or replace function public_activity_feed(p_limit int default 8)
returns table (
  id uuid,
  genre text,
  object_type_id text,
  ville text,
  commune text,
  created_at timestamptz
)
language sql
security definer
stable
as $$
  select id, 'perdu' as genre, object_type_id, ville, commune, created_at
  from lost_reports
  where statut in ('active', 'correspondance', 'en_verification')
  union all
  select id, 'trouve' as genre, object_type_id, ville, commune, created_at
  from found_reports
  where statut = 'active'
  order by created_at desc
  limit greatest(p_limit, 1)
$$;

grant execute on function public_activity_feed(int) to anon, authenticated;

-- Ajoute le nombre de restitutions réussies aux statistiques publiques déjà
-- affichées sur la page d'accueil (trouvés, perdus, utilisateurs, villes).
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
    'villes', (select count(distinct ville) from found_reports),
    'restitutions', (select count(*) from lost_reports where statut = 'restituee')
  );
$$;
