// Notifications push réelles (Firebase Cloud Messaging, API HTTP v1) —
// envoyées aux appareils enregistrés via @capacitor/push-notifications
// (voir composables/usePushNotifications.js, qui écrit les jetons dans la
// table "push_tokens", migration_28). Sans cette pièce, la dépendance
// Capacitor présente dans package.json ne servait à rien : aucun jeton
// n'était collecté, et rien n'était jamais envoyé.
//
// Configuration (.env) — un seul réglage nécessaire, le compte de service
// Firebase complet (Console Firebase > Paramètres du projet > Comptes de
// service > Générer une nouvelle clé privée), collé tel quel en JSON sur
// une seule ligne dans FIREBASE_SERVICE_ACCOUNT_JSON :
//   FIREBASE_SERVICE_ACCOUNT_JSON={"type":"service_account","project_id":"...","private_key":"...","client_email":"...", ...}
// Tant que cette variable est vide, l'envoi est ignoré silencieusement
// (best-effort) — voir server/utils/recuDon.js pour le repli sur une
// notification in-app classique dans ce cas.
//
// Implémentation "à la main" (pas de SDK firebase-admin) : on signe
// nous-mêmes un JWT RS256 avec la clé privée du compte de service, on
// l'échange contre un jeton d'accès OAuth2 auprès de Google, puis on
// appelle l'API FCM v1 — même approche que server/utils/mtnMomo.js
// (jeton mis en cache le temps de sa validité).
import { createSign } from 'node:crypto'

const base64url = (buffer) =>
  buffer.toString('base64').replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '')

let jetonEnCache = null // { valeur, expireLe }

const lireCompteService = (config) => {
  const brut = config.firebase?.serviceAccountJson
  if (!brut) return null
  try {
    return JSON.parse(brut)
  } catch (e) {
    return null
  }
}

const obtenirJetonFcm = async (compteService) => {
  if (jetonEnCache && jetonEnCache.expireLe > Date.now()) return jetonEnCache.valeur

  const maintenant = Math.floor(Date.now() / 1000)
  const entete = base64url(Buffer.from(JSON.stringify({ alg: 'RS256', typ: 'JWT' })))
  const revendications = base64url(Buffer.from(JSON.stringify({
    iss: compteService.client_email,
    scope: 'https://www.googleapis.com/auth/firebase.messaging',
    aud: 'https://oauth2.googleapis.com/token',
    iat: maintenant,
    exp: maintenant + 3600
  })))

  const signataire = createSign('RSA-SHA256')
  signataire.update(`${entete}.${revendications}`)
  const signature = base64url(signataire.sign(compteService.private_key))

  const assertion = `${entete}.${revendications}.${signature}`

  const reponse = await $fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion
    }).toString()
  })

  jetonEnCache = {
    valeur: reponse.access_token,
    expireLe: Date.now() + (Number(reponse.expires_in || 3500) - 60) * 1000
  }
  return jetonEnCache.valeur
}

/**
 * Envoie une notification push à une liste de jetons d'appareil.
 * Retourne { envoye, jetonsInvalides } : jetonsInvalides liste les jetons
 * rejetés par FCM comme périmés/désinstallés (NOT_FOUND / UNREGISTERED),
 * à retirer de la table "push_tokens" par l'appelant.
 */
export const envoyerPush = async ({ jetons, titre, corps, lien }) => {
  const config = useRuntimeConfig()
  const compteService = lireCompteService(config)

  if (!compteService) {
    return { envoye: false, raison: 'FIREBASE_SERVICE_ACCOUNT_JSON non configurée sur le serveur.', jetonsInvalides: [] }
  }
  if (!jetons?.length) {
    return { envoye: false, raison: 'Aucun appareil enregistré pour cet utilisateur.', jetonsInvalides: [] }
  }

  let accessToken
  try {
    accessToken = await obtenirJetonFcm(compteService)
  } catch (e) {
    return { envoye: false, raison: "Impossible d'obtenir un jeton d'accès Google (clé de service invalide ?).", jetonsInvalides: [] }
  }

  const jetonsInvalides = []
  let auMoinsUnEnvoi = false

  await Promise.all(jetons.map(async (jeton) => {
    try {
      await $fetch(`https://fcm.googleapis.com/v1/projects/${compteService.project_id}/messages:send`, {
        method: 'POST',
        headers: { Authorization: `Bearer ${accessToken}` },
        body: {
          message: {
            token: jeton,
            notification: { title: titre, body: corps },
            data: lien ? { lien } : undefined
          }
        }
      })
      auMoinsUnEnvoi = true
    } catch (e) {
      const statut = e?.data?.error?.status
      if (statut === 'NOT_FOUND' || statut === 'UNREGISTERED' || statut === 'INVALID_ARGUMENT') {
        jetonsInvalides.push(jeton)
      }
    }
  }))

  return { envoye: auMoinsUnEnvoi, jetonsInvalides }
}
