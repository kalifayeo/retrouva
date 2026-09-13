// Limite de fréquence anti-spam pour la création de dons, basée sur la
// base de données (et non la mémoire du process) car les fonctions
// serverless (Vercel) ne partagent pas leur mémoire entre invocations :
// une limite en mémoire serait inutile en production.
//
// Règle : au plus 3 dons créés depuis la même adresse IP sur une fenêtre
// de 10 minutes. Volontairement simple (pas de dépendance externe type
// Redis) — largement suffisant pour empêcher un script de remplir la
// table "donations" en boucle, sans gêner un vrai donateur.

const FENETRE_MINUTES = 10
const MAX_DONS_PAR_FENETRE = 3

export const ipDepuisRequete = (event) => {
  // getRequestIP gère X-Forwarded-For correctement sur Vercel si
  // { xForwardedFor: true } (voir appel ci-dessous).
  return getRequestIP(event, { xForwardedFor: true }) || 'inconnue'
}

export const verifierLimiteDons = async (admin, ip) => {
  if (!ip || ip === 'inconnue') return // on ne bloque jamais faute de mieux, mais ce cas est rare

  const depuis = new Date(Date.now() - FENETRE_MINUTES * 60 * 1000).toISOString()
  const { count, error } = await admin
    .from('donations')
    .select('id', { count: 'exact', head: true })
    .eq('ip_creation', ip)
    .gte('created_at', depuis)

  if (error) return // en cas d'erreur de comptage, on ne bloque pas un vrai donateur

  if ((count || 0) >= MAX_DONS_PAR_FENETRE) {
    throw createError({
      statusCode: 429,
      statusMessage: 'Trop de dons créés récemment depuis cette connexion. Réessayez dans quelques minutes.'
    })
  }
}
