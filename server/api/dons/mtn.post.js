// POST /api/dons/mtn
// Déclenche une demande de paiement MTN Mobile Money (API Collections,
// "Request to Pay") : un prompt d'autorisation est envoyé directement sur le
// téléphone du donateur, qu'il doit valider avec son code secret Mobile
// Money. Aucune URL de redirection n'est renvoyée ici — le statut se
// consulte ensuite via GET /api/dons/mtn-statut?ref=<referenceId>.
// Documentation : https://momodeveloper.mtn.com
import { randomUUID } from 'node:crypto'

export default defineEventHandler(async (event) => {
  const config = useRuntimeConfig()
  if (!config.mtnMomo?.subscriptionKey || !config.mtnMomo?.apiUser || !config.mtnMomo?.apiKey) {
    throw createError({
      statusCode: 500,
      statusMessage: "Le paiement MTN Mobile Money n'est pas configuré sur le serveur."
    })
  }

  const body = await readBody(event)
  const montant = Number(body?.montant)
  // Le numéro doit être au format international sans "+" (ex. 2250546229778).
  const telephone = String(body?.telephone || '').replace(/\D/g, '')
  if (!Number.isFinite(montant) || montant <= 0) {
    throw createError({ statusCode: 400, statusMessage: 'Montant invalide.' })
  }
  if (telephone.length < 8) {
    throw createError({ statusCode: 400, statusMessage: 'Numéro Mobile Money invalide.' })
  }

  const referenceId = randomUUID()

  const reference = String(body?.reference || '').trim()

  try {
    const jeton = await obtenirJetonMtn(config)
    await $fetch(`${config.mtnMomo.baseUrl}/collection/v1_0/requesttopay`, {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${jeton}`,
        'X-Reference-Id': referenceId,
        'X-Target-Environment': config.mtnMomo.targetEnvironment,
        'Ocp-Apim-Subscription-Key': config.mtnMomo.subscriptionKey,
        'Content-Type': 'application/json'
      },
      body: {
        // L'environnement sandbox MTN n'accepte que la devise EUR pour les
        // tests ; la production utilise XOF (FCFA).
        amount: String(Math.round(montant)),
        currency: config.mtnMomo.targetEnvironment === 'sandbox' ? 'EUR' : 'XOF',
        externalId: String(reference || referenceId).slice(0, 64),
        payer: { partyIdType: 'MSISDN', partyId: telephone },
        payerMessage: 'Don RETROUVA',
        payeeNote: 'Merci pour votre don RETROUVA'
      }
    })

    // On relie ce referenceId MTN (X-Reference-Id) à la ligne "donations"
    // déjà créée, pour que GET /api/dons/mtn-statut puisse la retrouver et
    // la mettre à jour une fois le paiement validé (ou refusé) sur le
    // téléphone du donateur. Non bloquant si ça échoue.
    if (reference) {
      try {
        const admin = supabaseAdmin()
        await admin
          .from('donations')
          .update({ provider: 'mtn', provider_reference: referenceId })
          .eq('reference', reference)
      } catch (e) { /* non bloquant */ }
    }

    return { referenceId }
  } catch (e) {
    throw createError({
      statusCode: 502,
      statusMessage: e?.data?.message || "Impossible de contacter MTN Mobile Money pour le moment."
    })
  }
})
