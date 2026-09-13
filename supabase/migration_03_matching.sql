-- =========================================================
-- RETROUVA — Migration 03 : moteur de correspondance automatique
-- =========================================================
-- À exécuter une fois dans Supabase > SQL Editor (après migration_02).
-- Calcule un score de correspondance (0 à 100) entre déclarations perdues
-- et trouvées, se déclenche automatiquement à chaque nouvelle déclaration,
-- et notifie le propriétaire quand le score est fort.
-- =========================================================

-- ---------------------------------------------------------
-- 1) Colonne de suivi : évite de notifier deux fois la même correspondance
-- ---------------------------------------------------------
alter table matches add column if not exists notifie boolean not null default false;

-- ---------------------------------------------------------
-- 2) Calcule les correspondances pour UNE déclaration PERDUE donnée,
--    en la comparant à toutes les déclarations TROUVÉES actives.
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
    least(100,
      40 * (fr.ville = lr.ville)::int
      + 20 * (fr.commune is not null and lr.commune is not null and fr.commune = lr.commune)::int
      + case
          when abs(fr.date_trouvaille - lr.date_perte) <= 3  then 40
          when abs(fr.date_trouvaille - lr.date_perte) <= 7  then 30
          when abs(fr.date_trouvaille - lr.date_perte) <= 14 then 20
          when abs(fr.date_trouvaille - lr.date_perte) <= 30 then 10
          else 0
        end
    ) as score,
    jsonb_build_object(
      'type_identique', true,
      'ville_identique', fr.ville = lr.ville,
      'commune_identique', fr.commune is not null and lr.commune is not null and fr.commune = lr.commune,
      'ecart_jours', abs(fr.date_trouvaille - lr.date_perte)
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

  -- Notifie le propriétaire (une seule fois par correspondance)
  insert into notifications (user_id, titre, corps, type)
  select lr.user_id,
    'Correspondance trouvée',
    'Une déclaration pourrait correspondre à votre objet perdu (score ' || m.score || '%).',
    'correspondance'
  from matches m
  where m.lost_report_id = lr.id and m.score >= 70 and m.notifie = false;

  update matches set notifie = true
  where lost_report_id = lr.id and score >= 70 and notifie = false;
end;
$$;

-- ---------------------------------------------------------
-- 3) Calcule les correspondances pour UNE déclaration TROUVÉE donnée,
--    en la comparant à toutes les déclarations PERDUES actives.
--    (symétrique : utile quand l'objet trouvé est publié APRÈS la perte)
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
    least(100,
      40 * (fr.ville = lr.ville)::int
      + 20 * (fr.commune is not null and lr.commune is not null and fr.commune = lr.commune)::int
      + case
          when abs(fr.date_trouvaille - lr.date_perte) <= 3  then 40
          when abs(fr.date_trouvaille - lr.date_perte) <= 7  then 30
          when abs(fr.date_trouvaille - lr.date_perte) <= 14 then 20
          when abs(fr.date_trouvaille - lr.date_perte) <= 30 then 10
          else 0
        end
    ) as score,
    jsonb_build_object(
      'type_identique', true,
      'ville_identique', fr.ville = lr.ville,
      'commune_identique', fr.commune is not null and lr.commune is not null and fr.commune = lr.commune,
      'ecart_jours', abs(fr.date_trouvaille - lr.date_perte)
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
    'Correspondance trouvée',
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
-- 4) Déclencheurs : calcul automatique à chaque nouvelle déclaration
-- ---------------------------------------------------------
create or replace function trg_matching_apres_perte()
returns trigger language plpgsql as $$
begin
  perform calculer_matches_pour_perdu(new.id);
  return new;
end;
$$;

drop trigger if exists after_lost_report_insert on lost_reports;
create trigger after_lost_report_insert
  after insert on lost_reports
  for each row execute function trg_matching_apres_perte();

create or replace function trg_matching_apres_trouve()
returns trigger language plpgsql as $$
begin
  perform calculer_matches_pour_trouve(new.id);
  return new;
end;
$$;

drop trigger if exists after_found_report_insert on found_reports;
create trigger after_found_report_insert
  after insert on found_reports
  for each row execute function trg_matching_apres_trouve();

-- ---------------------------------------------------------
-- 5) Rattrapage : calcule les correspondances pour les déclarations déjà
--    existantes dans votre base (celles créées avant cette migration).
-- ---------------------------------------------------------
select calculer_matches_pour_perdu(id) from lost_reports where statut in ('active', 'correspondance');
