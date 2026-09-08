-- =========================================================
-- RETROUVA — Migration 13 : carte interactive + espace publicitaire
-- =========================================================

-- Agrégats publics par ville pour la carte interactive (aucune donnée
-- personnelle exposée — uniquement des compteurs par ville).
create or replace function public_carte_data()
returns table(ville text, perdus bigint, trouves bigint)
language sql
security definer
stable
as $$
  select
    coalesce(l.ville, f.ville) as ville,
    coalesce(l.cnt, 0) as perdus,
    coalesce(f.cnt, 0) as trouves
  from
    (select ville, count(*) cnt from lost_reports where statut in ('active','correspondance') group by ville) l
  full outer join
    (select ville, count(*) cnt from found_reports where statut = 'active' group by ville) f
  on l.ville = f.ville;
$$;

grant execute on function public_carte_data() to anon, authenticated;
