-- =========================================================
-- RETROUVA — Migration 21 : chat de support (bouton flottant),
-- numéro WhatsApp support, et vrais numéros de don
-- =========================================================
-- Additive uniquement, sans danger sur une base à jour jusqu'à la
-- migration 20.

-- ---------------------------------------------------------
-- 1) CHAT DE SUPPORT TECHNIQUE
-- ---------------------------------------------------------
-- Une conversation par "visiteur" : son id de profil s'il est connecté,
-- sinon un identifiant anonyme généré et gardé dans son navigateur
-- (localStorage). Gérée depuis /admin/support.
create table if not exists support_messages (
  id uuid primary key default uuid_generate_v4(),
  conversation_id text not null,
  auteur text not null default 'utilisateur', -- 'utilisateur' | 'admin'
  nom_visiteur text,
  contenu text not null,
  lu boolean not null default false,
  created_at timestamptz not null default now()
);

alter table support_messages enable row level security;

-- Chacun peut écrire dans le support (connecté ou non) ; la lecture des
-- messages ne remonte que par conversation précise (le visiteur ne
-- connaît que la sienne côté client) ou intégralement pour l'admin.
create policy "support_messages_creation" on support_messages for insert with check (true);
create policy "support_messages_lecture" on support_messages for select using (true);
create policy "support_messages_maj_admin" on support_messages for update using (is_admin());

create index if not exists idx_support_messages_conversation on support_messages (conversation_id, created_at);

-- ---------------------------------------------------------
-- 2) NUMÉRO WHATSAPP DU SUPPORT (bouton flottant)
-- ---------------------------------------------------------
insert into site_settings (cle, valeur) values
  ('whatsapp_support_numero', '2250797676545')
on conflict (cle) do nothing;

-- ---------------------------------------------------------
-- 3) VRAIS NUMÉROS DE DON (remplacent les numéros d'exemple)
-- ---------------------------------------------------------
-- Ne touche que les 2 méthodes concernées, sans écraser une
-- modification déjà faite manuellement par l'admin dans /admin/dons.
update payment_methods set numero = '+225 07 97 67 65 45'
  where nom = 'Orange Money' and numero = '+225 07 00 00 00 00';
update payment_methods set numero = '+225 05 46 22 97 78'
  where nom = 'MTN Mobile Money' and numero = '+225 05 00 00 00 00';
update payment_methods set numero = '+225 07 97 67 65 45'
  where nom = 'Wave' and numero = '+225 01 00 00 00 00';
