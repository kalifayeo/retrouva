// Jeton OAuth Orange Money (Client Credentials) — mis en cache en mémoire
// process le temps de sa validité pour éviter une requête d'authentification
// à chaque don. Documentation : https://developer.orange.com/apis/om-webpay
let jetonEnCache = null // { valeur, expireLe }

export const obtenirJetonOrange = async (config) => {
  if (jetonEnCache && jetonEnCache.expireLe > Date.now()) return jetonEnCache.valeur

  const identifiants = Buffer
    .from(`${config.orangeMoney.clientId}:${config.orangeMoney.clientSecret}`)
    .toString('base64')

  const reponse = await $fetch('https://api.orange.com/oauth/v3/token', {
    method: 'POST',
    headers: {
      Authorization: `Basic ${identifiants}`,
      'Content-Type': 'application/x-www-form-urlencoded'
    },
    body: 'grant_type=client_credentials'
  })

  // Marge de sécurité d'une minute avant l'expiration réelle du jeton.
  jetonEnCache = {
    valeur: reponse.access_token,
    expireLe: Date.now() + (Number(reponse.expires_in || 3000) - 60) * 1000
  }
  return jetonEnCache.valeur
}

// Vérification officielle du statut d'une transaction (Transaction Status
// API d'Orange Money) — https://developer.orange.com/apis/om-webpay
//
// À NE JAMAIS remplacer par une simple confiance dans le contenu du
// webhook "notif_url" ou dans le paramètre d'URL de retour du navigateur :
// l'un comme l'autre peuvent être forgés par n'importe qui. Cet appel se
// fait serveur à serveur, avec le jeton OAuth de l'application, et est la
// seule source fiable pour savoir si un paiement a réellement abouti.
//
// Renvoie l'un de : 'INITIATED' | 'PENDING' | 'EXPIRED' | 'SUCCESS' | 'FAILED'
export const verifierStatutOrange = async (config, { orderId, amount, payToken }) => {
  const jeton = await obtenirJetonOrange(config)
  const reponse = await $fetch('https://api.orange.com/orange-money-webpay/ci/v1/transactionstatus', {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${jeton}`,
      'Content-Type': 'application/json',
      Accept: 'application/json'
    },
    body: {
      order_id: orderId,
      amount: Math.round(Number(amount)),
      pay_token: payToken
    }
  })
  return { statut: reponse.status, txnid: reponse.txnid || null }
}
