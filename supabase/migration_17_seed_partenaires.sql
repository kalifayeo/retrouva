-- =========================================================
-- RETROUVA — Migration 17 : amorçage du réseau de partenaires
-- =========================================================
-- La page /points-relais affichait des données 100% statiques (en dur
-- dans le composant), non connectées à la table `pickup_points`
-- pourtant déjà prévue en base. On amorce ici un premier réseau réel
-- à Abidjan, pour que la fonctionnalité soit enfin utilisable de bout
-- en bout (carte, page points relais, choix lors d'une remise).
--
-- Idempotent : n'insère rien si des partenaires existent déjà.
-- =========================================================

insert into partners (nom, contact_email, actif)
select * from (values
  ('Mairie de Cocody', 'contact@cocody.ci', true),
  ('Mairie du Plateau', 'contact@plateau.ci', true),
  ('Commissariat du 16e Arrondissement', null, true),
  ('Centre commercial Cap Sud', 'accueil@capsud.ci', true),
  ('Gare Sotra Adjamé', null, true)
) as v(nom, contact_email, actif)
where not exists (select 1 from partners limit 1);

insert into pickup_points (partner_id, nom, ville, commune, adresse, horaires, latitude, longitude, actif)
select p.id, pp.nom, 'Abidjan', pp.commune, pp.adresse, pp.horaires, pp.lat, pp.lng, true
from (values
  ('Mairie de Cocody',                    'Point relais - Mairie de Cocody',        'Cocody',      'Boulevard Latrille, Cocody',            'Lun–Ven, 8h–16h30', 5.3600, -3.9850),
  ('Mairie du Plateau',                    'Point relais - Mairie du Plateau',       'Plateau',     'Avenue Chardy, Plateau',                 'Lun–Ven, 8h–17h',   5.3200, -4.0170),
  ('Commissariat du 16e Arrondissement',   'Point relais - Commissariat Yopougon',   'Yopougon',    'Yopougon Sideci',                        'Ouvert 24h/24',     5.3450, -4.0850),
  ('Centre commercial Cap Sud',            'Point relais - Cap Sud Marcory',         'Marcory',     'Boulevard VGE, Marcory',                 'Lun–Dim, 9h–21h',   5.3000, -3.9800),
  ('Gare Sotra Adjamé',                    'Point relais - Gare Sotra Adjamé',       'Adjamé',      'Gare routière, Adjamé',                  'Lun–Dim, 6h–20h',   5.3550, -4.0280)
) as pp(partner_nom, nom, commune, adresse, horaires, lat, lng)
join partners p on p.nom = pp.partner_nom
where not exists (select 1 from pickup_points limit 1);
