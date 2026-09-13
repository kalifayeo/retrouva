-- =========================================================
-- RETROUVA — Migration 11 : introduction / présentation au premier lancement
-- =========================================================
-- Diapositives d'accueil affichées automatiquement à la première visite,
-- entièrement gérables depuis l'administration (texte, icône, ordre).

create table if not exists onboarding_slides (
  id uuid primary key default uuid_generate_v4(),
  titre text not null,
  description text,
  icone text not null default 'card',
  ordre integer not null default 0,
  actif boolean not null default true,
  created_by uuid references profiles(id),
  created_at timestamptz not null default now()
);

alter table onboarding_slides enable row level security;

create policy "onboarding_lecture" on onboarding_slides for select using (actif = true or public.is_admin());
create policy "onboarding_ecriture" on onboarding_slides for all using (public.is_admin()) with check (public.is_admin());

-- Diapositives de démarrage (uniquement si la table est encore vide)
insert into onboarding_slides (titre, description, icone, ordre)
select * from (values
  ('Bienvenue sur RETROUVA', 'La plateforme ivoirienne qui aide à retrouver, connecter et restituer les objets et documents perdus.', 'pin', 1),
  ('Déclarez une perte ou une trouvaille', 'Décrivez l''objet en quelques informations. Aucune donnée sensible n''est jamais publiée.', 'card', 2),
  ('Correspondance automatique', 'Notre moteur compare vos déclarations et vous notifie dès qu''une correspondance sérieuse est trouvée.', 'search', 3),
  ('Vérification et restitution sécurisées', 'Échangez via notre messagerie interne pour vérifier l''identité avant toute remise.', 'shield', 4)
) as t(titre, description, icone, ordre)
where not exists (select 1 from onboarding_slides);
