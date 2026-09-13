-- =========================================================
-- RETROUVA — Migration 14 : matching multi-critères avancé
-- =========================================================
-- À exécuter après migration_13. Améliore (sans les recréer) les fonctions
-- de calcul de correspondance mises en place en migration_03 : on garde les
-- mêmes tables, les mêmes triggers, la même signature de fonctions — on
-- ajoute simplement un critère de similarité de texte sur la description
-- (couleur, marque, signe distinctif...) en plus de la ville/commune/date
-- déjà utilisées, avec un score mieux réparti sur 100 points.
--
-- Rappel : le score n'est JAMAIS une preuve de propriété. Il sert
-- uniquement à faire remonter des correspondances potentielles ; l'étape
-- de vérification (verification_requests) reste obligatoire avant toute
-- mise en relation.
-- =========================================================

-- ---------------------------------------------------------
-- 1) Extension nécessaire à la similarité de texte (déjà présente sur la
--    plupart des projets Supabase ; sans danger si déjà installée).
-- ---------------------------------------------------------
create extension if not exists pg_trgm;

-- ---------------------------------------------------------
-- 2) Nouvelle répartition du score (total 100) :
--    - Ville identique             : 25 pts (condition minimale déjà appliquée)
--    - Commune identique           : 15 pts
--    - Proximité de date           : jusqu'à 30 pts (dégressif)
--    - Similarité de description   : jusqu'à 30 pts (couleur, marque, signe
--      distinctif... comparés via trigrammes, insensible à la casse/accents)
-- ---------------------------------------------------------
create or replace function calculer_matches_pour_perdu(p_lost_report_id uuid)
returns void
language plpgsql
security definer
as $$
declare
  lr lost_reports%rowtype;
begin
  select * into lr from lost_reports where id = p_lost_report_id;
  if lr.id is null then return; end if;

  insert into matches (lost_report_id, found_report_id, score, details)
  select
    lr.id,
    fr.id,
    least(100, round(
      25 * (fr.ville = lr.ville)::int
      + 15 * (fr.commune is not null and lr.commune is not null and fr.commune = lr.commune)::int
      + case
          when abs(fr.date_trouvaille - lr.date_perte) <= 3  then 30
          when abs(fr.date_trouvaille - lr.date_perte) <= 7  then 22
          when abs(fr.date_trouvaille - lr.date_perte) <= 14 then 14
          when abs(fr.date_trouvaille - lr.date_perte) <= 30 then 6
          else 0
        end
      + 30 * greatest(
          coalesce(similarity(unaccent(lower(fr.description)), unaccent(lower(lr.description))), 0),
          0
        )
    )) as score,
    jsonb_build_object(
      'type_identique', true,
      'ville_identique', fr.ville = lr.ville,
      'commune_identique', fr.commune is not null and lr.commune is not null and fr.commune = lr.commune,
      'ecart_jours', abs(fr.date_trouvaille - lr.date_perte),
      'description_similaire', coalesce(similarity(unaccent(lower(fr.description)), unaccent(lower(lr.description))), 0) >= 0.35
    ) as details
  from found_reports fr
  where fr.object_type_id = lr.object_type_id
    and fr.statut = 'active'
    and fr.ville = lr.ville                              -- même ville = condition minimale
    and abs(fr.date_trouvaille - lr.date_perte) <= 60     -- fenêtre de 60 jours
  on conflict (lost_report_id, found_report_id)
  do update set score = excluded.score, details = excluded.details;

  -- Marque la déclaration comme "correspondance" dès qu'un score fort existe
  update lost_reports set statut = 'correspondance'
  where id = lr.id and statut = 'active'
    and exists (select 1 from matches where lost_report_id = lr.id and score >= 70);

  -- Notifie le propriétaire (une seule fois par correspondance forte)
  insert into notifications (user_id, titre, corps, type)
  select lr.user_id,
    case when m.score >= 85 then 'Forte correspondance détectée' else 'Correspondance trouvée' end,
    'Une déclaration pourrait correspondre à votre objet perdu (score ' || m.score || '%).',
    'correspondance'
  from matches m
  where m.lost_report_id = lr.id and m.score >= 70 and m.notifie = false;

  update matches set notifie = true
  where lost_report_id = lr.id and score >= 70 and notifie = false;
end;
$$;

-- ---------------------------------------------------------
-- 3) Fonction symétrique pour une déclaration TROUVÉE, même logique.
-- ---------------------------------------------------------
create or replace function calculer_matches_pour_trouve(p_found_report_id uuid)
returns void
language plpgsql
security definer
as $$
declare
  fr found_reports%rowtype;
begin
  select * into fr from found_reports where id = p_found_report_id;
  if fr.id is null then return; end if;

  insert into matches (lost_report_id, found_report_id, score, details)
  select
    lr.id,
    fr.id,
    least(100, round(
      25 * (fr.ville = lr.ville)::int
      + 15 * (fr.commune is not null and lr.commune is not null and fr.commune = lr.commune)::int
      + case
          when abs(fr.date_trouvaille - lr.date_perte) <= 3  then 30
          when abs(fr.date_trouvaille - lr.date_perte) <= 7  then 22
          when abs(fr.date_trouvaille - lr.date_perte) <= 14 then 14
          when abs(fr.date_trouvaille - lr.date_perte) <= 30 then 6
          else 0
        end
      + 30 * greatest(
          coalesce(similarity(unaccent(lower(fr.description)), unaccent(lower(lr.description))), 0),
          0
        )
    )) as score,
    jsonb_build_object(
      'type_identique', true,
      'ville_identique', fr.ville = lr.ville,
      'commune_identique', fr.commune is not null and lr.commune is not null and fr.commune = lr.commune,
      'ecart_jours', abs(fr.date_trouvaille - lr.date_perte),
      'description_similaire', coalesce(similarity(unaccent(lower(fr.description)), unaccent(lower(lr.description))), 0) >= 0.35
    ) as details
  from lost_reports lr
  where lr.object_type_id = fr.object_type_id
    and lr.statut in ('active', 'correspondance')
    and lr.ville = fr.ville
    and abs(fr.date_trouvaille - lr.date_perte) <= 60
  on conflict (lost_report_id, found_report_id)
  do update set score = excluded.score, details = excluded.details;

  update lost_reports lr set statut = 'correspondance'
  from matches m
  where m.found_report_id = fr.id and m.lost_report_id = lr.id
    and lr.statut = 'active' and m.score >= 70;

  insert into notifications (user_id, titre, corps, type)
  select lr.user_id,
    case when m.score >= 85 then 'Forte correspondance détectée' else 'Correspondance trouvée' end,
    'Une déclaration pourrait correspondre à votre objet perdu (score ' || m.score || '%).',
    'correspondance'
  from matches m
  join lost_reports lr on lr.id = m.lost_report_id
  where m.found_report_id = fr.id and m.score >= 70 and m.notifie = false;

  update matches set notifie = true
  where found_report_id = fr.id and score >= 70 and notifie = false;
end;
$$;

-- ---------------------------------------------------------
-- 4) unaccent : nécessaire pour comparer "téléphone" et "telephone".
--    (extension standard Postgres/Supabase, sans risque si déjà présente)
-- ---------------------------------------------------------
create extension if not exists unaccent;

-- ---------------------------------------------------------
-- 5) Les triggers existants (after_lost_report_insert / after_found_report_insert
--    de la migration_03) réutilisent automatiquement ces fonctions : rien à
--    recréer de ce côté.
-- ---------------------------------------------------------

-- ---------------------------------------------------------
-- 6) Rattrapage : recalcule les correspondances existantes avec le
--    nouveau score enrichi.
-- ---------------------------------------------------------
select calculer_matches_pour_perdu(id) from lost_reports where statut in ('active', 'correspondance');
