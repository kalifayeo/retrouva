-- =========================================================
-- RETROUVA — Migration 15 : rendre la vérification et la remise
-- réellement fonctionnelles (permissions manquantes en base)
-- =========================================================
-- Constat : les tables verification_requests, restitution_requests et
-- restitutions existaient déjà, mais leurs policies RLS étaient
-- incomplètes : personne ne pouvait ni lire une demande de vérification
-- en tant que "trouveur", ni la valider/rejeter, ni créer/mettre à jour
-- une remise. Cette migration complète les permissions, sans changer
-- une seule table ni le design existant.

-- ---------------------------------------------------------
-- 1) VERIFICATION_REQUESTS
--    - le "trouveur" (l'autre partie du match) doit pouvoir LIRE la
--      demande pour l'examiner ;
--    - le "trouveur" doit pouvoir la VALIDER ou la REJETER (colonne
--      `validee`) ; le demandeur ne doit pas pouvoir s'auto-valider.
-- ---------------------------------------------------------
create policy "verif_lecture_correspondant" on verification_requests for select using (
  exists (
    select 1 from matches m
    join found_reports fr on fr.id = m.found_report_id
    where m.id = verification_requests.match_id and fr.user_id = auth.uid()
  )
);

create policy "verif_validation_correspondant" on verification_requests for update using (
  exists (
    select 1 from matches m
    join found_reports fr on fr.id = m.found_report_id
    where m.id = verification_requests.match_id and fr.user_id = auth.uid()
  )
) with check (
  exists (
    select 1 from matches m
    join found_reports fr on fr.id = m.found_report_id
    where m.id = verification_requests.match_id and fr.user_id = auth.uid()
  )
);

-- ---------------------------------------------------------
-- 2) MATCHES
--    - autoriser les deux parties à mettre à jour leur match (ex :
--      masquer une correspondance rejetée après vérification).
-- ---------------------------------------------------------
create policy "matches_maj_participants" on matches for update using (
  exists (select 1 from lost_reports lr where lr.id = lost_report_id and lr.user_id = auth.uid())
  or exists (select 1 from found_reports fr where fr.id = found_report_id and fr.user_id = auth.uid())
);

-- ---------------------------------------------------------
-- 3) RESTITUTION_REQUESTS
--    - il manquait purement et simplement le droit de CRÉER une
--      demande de remise, et de la METTRE À JOUR (ex : annulation).
-- ---------------------------------------------------------
create policy "restitution_requests_creation" on restitution_requests for insert with check (
  auth.uid() = initiee_par
  and exists (
    select 1 from matches m
    join lost_reports lr on lr.id = m.lost_report_id
    join found_reports fr on fr.id = m.found_report_id
    where m.id = match_id and (lr.user_id = auth.uid() or fr.user_id = auth.uid())
  )
);

create policy "restitution_requests_maj" on restitution_requests for update using (
  exists (
    select 1 from matches m
    join lost_reports lr on lr.id = m.lost_report_id
    join found_reports fr on fr.id = m.found_report_id
    where m.id = match_id and (lr.user_id = auth.uid() or fr.user_id = auth.uid())
  )
);

-- ---------------------------------------------------------
-- 4) RESTITUTIONS
--    - la table n'avait AUCUNE policy : totalement inaccessible.
--      On l'ouvre en lecture/écriture aux deux parties du match
--      concerné, via restitution_requests.
-- ---------------------------------------------------------
create policy "restitutions_lecture" on restitutions for select using (
  exists (
    select 1 from restitution_requests rr
    join matches m on m.id = rr.match_id
    join lost_reports lr on lr.id = m.lost_report_id
    join found_reports fr on fr.id = m.found_report_id
    where rr.id = restitution_request_id and (lr.user_id = auth.uid() or fr.user_id = auth.uid())
  )
);

create policy "restitutions_creation" on restitutions for insert with check (
  exists (
    select 1 from restitution_requests rr
    join matches m on m.id = rr.match_id
    join lost_reports lr on lr.id = m.lost_report_id
    join found_reports fr on fr.id = m.found_report_id
    where rr.id = restitution_request_id and (lr.user_id = auth.uid() or fr.user_id = auth.uid())
  )
);

create policy "restitutions_maj" on restitutions for update using (
  exists (
    select 1 from restitution_requests rr
    join matches m on m.id = rr.match_id
    join lost_reports lr on lr.id = m.lost_report_id
    join found_reports fr on fr.id = m.found_report_id
    where rr.id = restitution_request_id and (lr.user_id = auth.uid() or fr.user_id = auth.uid())
  )
);

-- ---------------------------------------------------------
-- 5) Finalisation automatique : quand les deux parties ont confirmé la
--    restitution, on marque automatiquement les déclarations comme
--    récupérées/remises et on notifie tout le monde.
--    (fonction + trigger — aucune table recréée)
-- ---------------------------------------------------------
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

    insert into notifications (user_id, titre, corps, type)
    select lr.user_id, '✅ Objet récupéré', 'La restitution de votre objet a été confirmée par les deux parties.', 'restitution'
    from lost_reports lr where lr.id = v_match.lost_report_id
    union all
    select fr.user_id, '✅ Objet remis', 'La remise de l''objet a été confirmée. Merci pour votre aide !', 'restitution'
    from found_reports fr where fr.id = v_match.found_report_id;
  end if;
  return new;
end;
$$;

drop trigger if exists trg_finaliser_restitution on restitutions;
create trigger trg_finaliser_restitution
  before insert or update on restitutions
  for each row execute function finaliser_restitution();

-- ---------------------------------------------------------
-- 6) Notification automatique quand une vérification est validée ou
--    rejetée (le demandeur ne peut pas insérer lui-même de notification,
--    donc on le fait ici via une fonction security definer déclenchée
--    par la mise à jour de `validee`).
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
      insert into notifications (user_id, titre, corps, type)
      values (new.demandeur_id, '🔐 Identité vérifiée', 'Le trouveur a confirmé votre identité. Vous pouvez organiser la remise de l''objet.', 'verification');
    else
      insert into notifications (user_id, titre, corps, type)
      values (new.demandeur_id, '❌ Correspondance rejetée', 'Les éléments fournis ne correspondent pas à l''objet trouvé. RETROUVA continue la recherche.', 'verification');

      update lost_reports set statut = 'active' where id = v_match.lost_report_id and statut = 'en_verification';
      update matches set masque = true where id = new.match_id;
    end if;
  end if;
  return new;
end;
$$;

drop trigger if exists trg_notifier_resultat_verification on verification_requests;
create trigger trg_notifier_resultat_verification
  after update on verification_requests
  for each row execute function notifier_resultat_verification();

-- ---------------------------------------------------------
-- 7) Colonne `masque` sur matches si elle n'existe pas déjà (utilisée
--    ci-dessus pour cacher une correspondance rejetée sans la supprimer).
-- ---------------------------------------------------------
alter table matches add column if not exists masque boolean not null default false;

-- Les correspondances masquées ne doivent plus remonter dans /resultats
-- (la policy de lecture existante reste valable, le filtre se fait côté requête).
