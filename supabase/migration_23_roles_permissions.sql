-- =========================================================
-- RETROUVA — Migration 23 : mise en application réelle des rôles
-- 'moderateur', 'partenaire' et 'agent_relais' (déjà présents dans
-- l'enum user_role depuis le tout début, mais sans aucun middleware ni
-- policy dédiée jusqu'ici — voir la note en tête de useAdminPermissions.js
-- côté front pour le détail de qui doit voir quoi).
--
-- Additive et idempotente : peut être rejouée sans danger sur une base
-- déjà à jour jusqu'à la migration 22. Ne modifie ni ne supprime aucune
-- donnée existante ; ne touche à aucune policy qui ne soit pas listée
-- explicitement ci-dessous.
-- =========================================================

-- ---------------------------------------------------------
-- 0) FONCTIONS UTILITAIRES DE RÔLE
--    (même principe que is_admin(), défini en migration_02 / schema.sql)
-- ---------------------------------------------------------
create or replace function is_moderateur_ou_plus()
returns boolean
language sql
security definer
stable
as $$
  select exists (
    select 1 from profiles
    where id = auth.uid()
    and role in ('administrateur', 'super_administrateur', 'moderateur')
  );
$$;

create or replace function is_super_admin()
returns boolean
language sql
security definer
stable
as $$
  select exists (
    select 1 from profiles
    where id = auth.uid()
    and role = 'super_administrateur'
  );
$$;

-- ---------------------------------------------------------
-- 1) MODERATEUR — signalements (table "reports")
--    Peut lire et faire évoluer le statut d'un signalement, comme un
--    administrateur. Les autres tables admin (dons, contenu, bannières,
--    rôles…) restent réservées à is_admin() : un modérateur qui
--    appellerait l'API directement dessus resterait bloqué.
-- ---------------------------------------------------------
drop policy if exists "admin_lecture_reports" on reports;
create policy "reports_lecture_staff" on reports for select using (is_moderateur_ou_plus());

drop policy if exists "admin_maj_reports" on reports;
create policy "reports_maj_staff" on reports for update using (is_moderateur_ou_plus());
-- La suppression d'un signalement reste réservée à administrateur/super_administrateur
-- ("admin_suppression_reports", créée en schema.sql, inchangée).

-- ---------------------------------------------------------
-- 2) MODERATEUR — support technique (table "support_messages")
--    La lecture et la création sont déjà ouvertes à tous (nécessaire au
--    chat flottant public) ; seule la mise à jour ("marquer lu") était
--    réservée à is_admin(). On l'étend au modérateur.
-- ---------------------------------------------------------
drop policy if exists "support_messages_maj_admin" on support_messages;
create policy "support_messages_maj_staff" on support_messages for update using (is_moderateur_ou_plus());

-- ---------------------------------------------------------
-- 3) MODERATEUR — déclarations (tables "lost_reports" / "found_reports")
--    Lecture déjà ouverte à tout utilisateur connecté (policies
--    "lost_reports_lecture" / "found_reports_lecture"). On ajoute la
--    capacité de mise à jour (masquage via le champ "statut", depuis
--    /admin/declarations) réservée jusqu'ici à is_admin(). La suppression
--    définitive, elle, reste hors de portée du modérateur : on ne touche
--    pas à "admin_suppression_lost_reports" / "admin_suppression_found_reports".
-- ---------------------------------------------------------
drop policy if exists "moderateur_maj_lost_reports" on lost_reports;
create policy "moderateur_maj_lost_reports" on lost_reports for update using (is_moderateur_ou_plus());

drop policy if exists "moderateur_maj_found_reports" on found_reports;
create policy "moderateur_maj_found_reports" on found_reports for update using (is_moderateur_ou_plus());

-- ---------------------------------------------------------
-- 4) ADMINISTRATEUR vs SUPER_ADMINISTRATEUR — restrictions fines
--    Jusqu'ici is_admin() (donc administrateur ET super_administrateur)
--    pouvait changer le rôle d'un compte et configurer les moyens de
--    paiement. On resserre ces deux points au seul super_administrateur,
--    conformément à la proposition validée ; le reste du panneau admin
--    (déclarations, correspondances, signalements, partenaires, contenu,
--    bannières, pop-up, événements, introduction, suivi des dons déjà
--    reçus…) reste accessible aux deux comme avant.
-- ---------------------------------------------------------

-- 4a) Verrou de changement de rôle (redéfinit la fonction de migration_19 :
--     remplace la condition is_admin() par is_super_admin()).
create or replace function proteger_role_profil()
returns trigger
language plpgsql
security definer
as $$
begin
  if new.role is distinct from old.role and not is_super_admin() then
    new.role := old.role;
  end if;
  return new;
end;
$$;
-- Le trigger "trg_proteger_role_profil" existant (migration_19) pointe déjà
-- vers cette fonction : aucune modification de trigger nécessaire, seule la
-- fonction change de comportement.

-- 4b) Moyens de paiement : configuration réservée au super_administrateur
--     (le suivi/confirmation des dons reçus, dans "donations", n'est PAS
--     concerné et reste accessible à l'administrateur — voir "donations_ecriture"
--     inchangée en schema.sql).
drop policy if exists "payment_methods_ecriture" on payment_methods;
create policy "payment_methods_ecriture" on payment_methods for all using (is_super_admin()) with check (is_super_admin());

-- ---------------------------------------------------------
-- 5) PARTENAIRE / AGENT_RELAIS — rattachement en base
--    Un compte "partenaire" est rattaché à UN partenaire (partners.id) ;
--    un compte "agent_relais" est rattaché à UN point relais précis
--    (pickup_points.id) où il travaille physiquement. Ces deux colonnes
--    sont nullables : un profil "utilisateur" ordinaire n'est concerné
--    par aucune des deux.
-- ---------------------------------------------------------
alter table profiles add column if not exists partner_id uuid references partners(id) on delete set null;
alter table profiles add column if not exists pickup_point_id uuid references pickup_points(id) on delete set null;

create index if not exists idx_profiles_partner_id on profiles (partner_id);
create index if not exists idx_profiles_pickup_point_id on profiles (pickup_point_id);

-- Fonctions utilitaires : le point relais assigné à l'utilisateur connecté
-- (agent), et le partenaire assigné (partenaire) — utilisées dans les
-- policies ci-dessous.
create or replace function mon_pickup_point_id()
returns uuid
language sql
security definer
stable
as $$
  select pickup_point_id from profiles where id = auth.uid();
$$;

create or replace function mon_partner_id()
returns uuid
language sql
security definer
stable
as $$
  select partner_id from profiles where id = auth.uid();
$$;

-- ---------------------------------------------------------
-- 6) PARTENAIRE — statistiques de son propre point relais
--    "restitution_requests" / "restitutions" ne sont aujourd'hui visibles
--    que par les 2 parties de la correspondance (propriétaire/trouveur)
--    ou par is_admin(). On ajoute la lecture pour le partenaire concerné,
--    strictement limitée aux remises passant par UN de ses points relais.
--    On lui ouvre aussi la lecture de SES points relais même inactifs
--    (la policy publique existante ne montre que les points "actif = true").
-- ---------------------------------------------------------
drop policy if exists "pickup_points_lecture_partenaire" on pickup_points;
create policy "pickup_points_lecture_partenaire" on pickup_points for select using (
  partner_id = mon_partner_id() and mon_partner_id() is not null
);

drop policy if exists "restitution_requests_lecture_partenaire" on restitution_requests;
create policy "restitution_requests_lecture_partenaire" on restitution_requests for select using (
  exists (
    select 1 from pickup_points pp
    where pp.id = restitution_requests.pickup_point_id
    and pp.partner_id = mon_partner_id()
    and mon_partner_id() is not null
  )
);

drop policy if exists "restitutions_lecture_partenaire" on restitutions;
create policy "restitutions_lecture_partenaire" on restitutions for select using (
  exists (
    select 1 from restitution_requests rr
    join pickup_points pp on pp.id = rr.pickup_point_id
    where rr.id = restitutions.restitution_request_id
    and pp.partner_id = mon_partner_id()
    and mon_partner_id() is not null
  )
);

-- ---------------------------------------------------------
-- 7) AGENT_RELAIS — confirmation de réception/remise physique
--    Nouvelles colonnes de suivi sur "restitutions" : indépendantes des
--    confirmations propriétaire/trouveur existantes (qui continuent de
--    déclencher la restitution automatique comme avant, voir
--    finaliser_restitution() en migration_16) — la confirmation de
--    l'agent est un enregistrement complémentaire de traçabilité au point
--    relais, elle ne bloque ni ne remplace le circuit actuel.
-- ---------------------------------------------------------
alter table restitutions add column if not exists confirmee_par_agent boolean not null default false;
alter table restitutions add column if not exists agent_id uuid references profiles(id) on delete set null;
alter table restitutions add column if not exists date_confirmation_agent timestamptz;

-- Lecture : l'agent voit les dossiers de remise concernant SON point relais.
drop policy if exists "restitution_requests_lecture_agent" on restitution_requests;
create policy "restitution_requests_lecture_agent" on restitution_requests for select using (
  restitution_requests.pickup_point_id = mon_pickup_point_id()
  and mon_pickup_point_id() is not null
);

drop policy if exists "restitutions_lecture_agent" on restitutions;
create policy "restitutions_lecture_agent" on restitutions for select using (
  exists (
    select 1 from restitution_requests rr
    where rr.id = restitutions.restitution_request_id
    and rr.pickup_point_id = mon_pickup_point_id()
    and mon_pickup_point_id() is not null
  )
);

-- Écriture : l'agent peut créer/mettre à jour la ligne de suivi de SON
-- point relais uniquement (l'interface /agent-relais n'écrit que dans les
-- 3 colonnes ajoutées ci-dessus, mais la policy reste au niveau ligne,
-- comme pour le reste du projet).
drop policy if exists "restitutions_creation_agent" on restitutions;
create policy "restitutions_creation_agent" on restitutions for insert with check (
  exists (
    select 1 from restitution_requests rr
    where rr.id = restitutions.restitution_request_id
    and rr.pickup_point_id = mon_pickup_point_id()
    and mon_pickup_point_id() is not null
  )
);

drop policy if exists "restitutions_maj_agent" on restitutions;
create policy "restitutions_maj_agent" on restitutions for update using (
  exists (
    select 1 from restitution_requests rr
    where rr.id = restitutions.restitution_request_id
    and rr.pickup_point_id = mon_pickup_point_id()
    and mon_pickup_point_id() is not null
  )
);
