// POST /api/dons/wave-webhook
// N'existait pas avant cette révision : Wave n'était relié à aucun
// webhook, donc un don "payé" via Wave ne pouvait jamais être confirmé
// automatiquement. À configurer côté Wave Business Portal → Développeur →
// Webhooks, avec cette URL, et à activer la "signature de requête"
// (request signing) sur la clé API pour obtenir WAVE_WEBHOOK_SECRET.
//
// Vérification de signature — voir https://docs.wave.com/webhook :
//   1) l'en-tête "Wave-Signature" contient "t=<timestamp>,v1=<signature>"
//      (et peut contenir PLUSIEURS "v1=" lors d'une rotation de secret —
//      il suffit qu'une seule corresponde)
//   2) le message signé est la CONCATÉNATION DIRECTE "<timestamp><corps
//      brut>" — sans séparateur (contrairement à des conventions comme
//      Stripe qui utilisent un point ; Wave n'en met pas).
//   3) la signature attendue = HMAC-SHA256(message, WAVE_WEBHOOK_SECRET)
// On compare en temps constant (timingSafeEqual) pour éviter les attaques
// par mesure de timing, et on rejette tout timestamp vieux de plus de 5
// minutes pour empêcher qu'un événement intercepté soit rejoué plus tard.
import { createHmac, timingSafeEqual } from 'node:crypto'

const TOLERANCE_SECONDES = 5 * 60

const comparerEnTempsConstant = (a, b) => {
  const bufA = Buffer.from(a, 'hex')
  const bufB = Buffer.from(b, 'hex')
  if (bufA.length !== bufB.length) return false
  return timingSafeEqual(bufA, bufB)
}

const verifierSignatureWave = (corpsBrut, enTete, secret) => {
  if (!enTete || !secret) return false

  const timestamp = enTete.match(/(?:^|,)\s*t=([^,]+)/)?.[1]
  // Une ou plusieurs signatures "v1=" possibles (rotation de secret) : on
  // accepte si la nôtre correspond à N'IMPORTE LAQUELLE d'entre elles.
  const signaturesRecues = [...enTete.matchAll(/(?:^|,)\s*v1=([^,]+)/g)].map((m) => m[1])
  if (!timestamp || !signaturesRecues.length) return false

  const age = Math.abs(Date.now() / 1000 - Number(timestamp))
  if (!Number.isFinite(age) || age > TOLERANCE_SECONDES) return false

  const signatureAttendue = createHmac('sha256', secret)
    .update(`${timestamp}${corpsBrut}`)
    .digest('hex')

  return signaturesRecues.some((sig) => comparerEnTempsConstant(signatureAttendue, sig))
}

export default defineEventHandler(async (event) => {
  const config = useRuntimeConfig()
  const corpsBrut = await readRawBody(event, 'utf8')
  const enTeteSignature = getHeader(event, 'wave-signature')

  if (!config.wave?.webhookSecret) {
    // Pas de secret configuré : on refuse plutôt que d'accepter sans
    // vérification, pour ne jamais confirmer un don sur la seule bonne foi.
    throw createError({ statusCode: 500, statusMessage: 'WAVE_WEBHOOK_SECRET non configurée.' })
  }

  if (!verifierSignatureWave(corpsBrut, enTeteSignature, config.wave.webhookSecret)) {
    throw createError({ statusCode: 401, statusMessage: 'Signature Wave invalide.' })
  }

  const evenement = JSON.parse(corpsBrut || '{}')
  const donneesSession = evenement?.data || {}
  const sessionId = String(donneesSession.id || '')
  const statutPaiement = donneesSession.payment_status // 'succeeded' | 'cancelled' | 'processing'...

  if (!sessionId) return { statut: 'ok' }

  const admin = supabaseAdmin()

  // Idempotence : l'id d'événement Wave (evenement.id) garantit qu'on ne
  // traite jamais deux fois le même envoi (y compris les retries de Wave
  // en cas de panne temporaire de notre côté).
  const { error: erreurEvenement } = await admin
    .from('payment_webhook_events')
    .insert({
      provider: 'wave',
      event_id: String(evenement.id || sessionId),
      ip_source: ipDepuisRequete(event),
      payload: evenement
    })
  if (erreurEvenement) return { statut: 'ok' } // doublon déjà traité

  const { data: don } = await admin
    .from('donations')
    .select('id, statut')
    .eq('provider_reference', sessionId)
    .eq('provider', 'wave')
    .maybeSingle()

  if (!don || don.statut === 'confirme') return { statut: 'ok' }

  if (statutPaiement === 'succeeded') {
    await admin
      .from('donations')
      .update({ statut: 'confirme', provider_transaction_id: sessionId, verified_at: new Date().toISOString() })
      .eq('id', don.id)
    // Best-effort : un paiement en ligne réussi déclenche le même reçu
    // (e-mail/SMS/notification) qu'une confirmation manuelle admin — voir
    // server/utils/recuDon.js.
    await envoyerRecuDon(admin, don.id).catch(() => {})
  } else if (statutPaiement === 'cancelled' || donneesSession.checkout_status === 'expired') {
    await admin
      .from('donations')
      .update({ statut: 'annule', verified_at: new Date().toISOString() })
      .eq('id', don.id)
  }

  return { statut: 'ok' }
})
