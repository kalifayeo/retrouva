-- =========================================================
-- RETROUVA — Nettoyage des déclarations de test en double
-- =========================================================
-- Supprime TOUTES vos déclarations perdues/trouvées et leurs
-- correspondances, pour repartir sur une base propre après vos tests.
-- Remplacez l'e-mail par le vôtre. Les correspondances (table "matches")
-- sont supprimées automatiquement grâce à ON DELETE CASCADE.

delete from lost_reports
where user_id = (select id from auth.users where email = 'kalifayeo11@gmail.com');

delete from found_reports
where user_id = (select id from auth.users where email = 'kalifayeo11@gmail.com');

-- Vérification : doit renvoyer 0 ligne
select count(*) as declarations_restantes from (
  select id from lost_reports where user_id = (select id from auth.users where email = 'kalifayeo11@gmail.com')
  union all
  select id from found_reports where user_id = (select id from auth.users where email = 'kalifayeo11@gmail.com')
) t;
