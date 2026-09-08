// Libellé du fil "Activité récente" : distingue les déclarations toujours en
// recherche des objets déjà restitués avec succès (voir migration_26).
// Partagé entre la page d'accueil (aperçu) et /activite-recente (flux complet)
// pour ne pas dupliquer la logique.
export const libelleActivite = (r) => {
  if (r.statut === 'restituee') return r.genre === 'perdu' ? 'récupéré par son propriétaire' : 'remis à son propriétaire'
  return r.genre === 'perdu' ? 'déclaré perdu' : 'retrouvé'
}
