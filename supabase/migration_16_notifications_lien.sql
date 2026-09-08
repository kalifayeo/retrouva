-- =========================================================
-- RETROUVA — Migration 16 : notifications cliquables (lien réel)
-- =========================================================
-- Ajoute une colonne `lien` (nullable, additive, sans casser l'existant)
-- pour que chaque notification puisse renvoyer vers la bonne page
-- (résultat de correspondance, conversation...) au lieu de rester un
-- simple texte informatif.

alter table notifications add column if not exists lien text;

-- ---------------------------------------------------------
-- Redéfinition des fonctions de matching (migration_14) pour inclure
-- le lien vers /resultats/<id_match> dans la notification.
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
    and fr.ville = lr.ville
    and abs(fr.date_trouvaille - lr.date_perte) <= 60
  on conflict (lost_report_id, found_report_id)
  do update set score = excluded.score, details = excluded.details;

  update lost_reports set statut = 'correspondance'
  where id = lr.id and statut = 'active'
    and exists (select 1 from matches where lost_report_id = lr.id and score >= 70);

  insert into notifications (user_id, titre, corps, type, lien)
  select lr.user_id,
    case when m.score >= 85 then 'Forte correspondance détectée' else 'Correspondance trouvée' end,
    'Une déclaration pourrait correspondre à votre objet perdu (score ' || m.score || '%).',
    'correspondance',
    '/resultats/' || m.id
  from matches m
  where m.lost_report_id = lr.id and m.score >= 70 and m.notifie = false;

  update matches set notifie = true
  where lost_report_id = lr.id and score >= 70 and notifie = false;
end;
$$;

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

  insert into notifications (user_id, titre, corps, type, lien)
  select lr.user_id,
    case when m.score >= 85 then 'Forte correspondance détectée' else 'Correspondance trouvée' end,
    'Une déclaration pourrait correspondre à votre objet perdu (score ' || m.score || '%).',
    'correspondance',
    '/resultats/' || m.id
  from matches m
  join lost_reports lr on lr.id = m.lost_report_id
  where m.found_report_id = fr.id and m.score >= 70 and m.notifie = false;

  update matches set notifie = true
  where found_report_id = fr.id and score >= 70 and notifie = false;
end;
$$;

-- ---------------------------------------------------------
-- Redéfinition des notifications de vérification/restitution
-- (migration_15) pour pointer vers la conversation concernée.
-- ---------------------------------------------------------
create or replace function notifier_resultat_verification()
returns trigger
language plpgsql
security definer
as $$
declare
  v_match matches%rowtype;
begin
  if new.validee is distinct from old.validee and new.validee is not null then
    select * into v_match from matches where id = new.match_id;

    if new.validee = true then
      insert into notifications (user_id, titre, corps, type, lien)
      values (new.demandeur_id, '🔐 Identité vérifiée', 'Le trouveur a confirmé votre identité. Vous pouvez organiser la remise de l''objet.', 'verification', '/messagerie/' || new.match_id);
    else
      insert into notifications (user_id, titre, corps, type, lien)
      values (new.demandeur_id, '❌ Correspondance rejetée', 'Les éléments fournis ne correspondent pas à l''objet trouvé. RETROUVA continue la recherche.', 'verification', '/mes-recherches');

      update lost_reports set statut = 'active' where id = v_match.lost_report_id and statut = 'en_verification';
      update matches set masque = true where id = new.match_id;
    end if;
  end if;
  return new;
end;
$$;

create or replace function finaliser_restitution()
returns trigger
language plpgsql
security definer
as $$
declare
  v_match matches%rowtype;
begin
  if new.confirmee_par_proprietaire = true and new.confirmee_par_trouveur = true then
    select m.* into v_match
    from restitution_requests rr
    join matches m on m.id = rr.match_id
    where rr.id = new.restitution_request_id;

    update lost_reports set statut = 'restituee' where id = v_match.lost_report_id;
    update found_reports set statut = 'restituee' where id = v_match.found_report_id;

    if new.date_restitution is null then
      new.date_restitution := now();
    end if;

    insert into notifications (user_id, titre, corps, type, lien)
    select lr.user_id, '✅ Objet récupéré', 'La restitution de votre objet a été confirmée par les deux parties.', 'restitution', '/mes-recherches'
    from lost_reports lr where lr.id = v_match.lost_report_id
    union all
    select fr.user_id, '✅ Objet remis', 'La remise de l''objet a été confirmée. Merci pour votre aide !', 'restitution', '/mes-objets-trouves'
    from found_reports fr where fr.id = v_match.found_report_id;
  end if;
  return new;
end;
$$;
