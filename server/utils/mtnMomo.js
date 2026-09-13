// Jeton d'accès MTN Mobile Money (API Collections) — mis en cache en
// mémoire process le temps de sa validité. Documentation :
// https://momodeveloper.mtn.com
let jetonEnCache = null // { valeur, expireLe }

export const obtenirJetonMtn = async (config) => {
  if (jetonEnCache && jetonEnCache.expireLe > Date.now()) return jetonEnCache.valeur

  const identifiants = Buffer
    .from(`${config.mtnMomo.apiUser}:${config.mtnMomo.apiKey}`)
    .toString('base64')

  const reponse = await $fetch(`${config.mtnMomo.baseUrl}/collection/token/`, {
    method: 'POST',
    headers: {
      Authorization: `Basic ${identifiants}`,
      'Ocp-Apim-Subscription-Key': config.mtnMomo.subscriptionKey
    }
  })

  jetonEnCache = {
    valeur: reponse.access_token,
    expireLe: Date.now() + (Number(reponse.expires_in || 3500) - 60) * 1000
  }
  return jetonEnCache.valeur
}
