// POST /api/dons/wave
// Crée une session de paiement Wave Checkout pour un don, et renvoie l'URL
// (`wave_launch_url`) vers laquelle rediriger le donateur pour finaliser le
// paiement dans l'app Wave. Documentation : https://docs.wave.com/checkout
//
// Ne fait JAMAIS confiance à un montant envoyé par le client sans le
// valider ici : on vérifie qu'il s'agit bien d'un nombre positif avant tout
// appel à l'API Wave.
export default defineEventHandler(async (event) => {
  const config = useRuntimeConfig()
  if (!config.wave?.apiKey) {
    throw createError({
      statusCode: 500,
      statusMessage: "Le paiement Wave n'est pas configuré sur le serveur (WAVE_API_KEY manquante)."
    })
  }

  const body = await readBody(event)
  const montant = Number(body?.montant)
  if (!Number.isFinite(montant) || montant <= 0) {
    throw createError({ statusCode: 400, statusMessage: 'Montant invalide.' })
  }
  const reference = String(body?.reference || '').slice(0, 64) || undefined

  const origine = getRequestURL(event).origin

  try {
    const session = await $fetch('https://api.wave.com/v1/checkout/sessions', {
      method: 'POST',
      headers: { Authorization: `Bearer ${config.wave.apiKey}` },
      body: {
        amount: String(Math.round(montant)),
        currency: 'XOF',
        client_reference: reference,
        success_url: `${origine}/don?paiement=succes&methode=wave&ref=${encodeURIComponent(reference || '')}`,
        error_url: `${origine}/don?paiement=echec&methode=wave&ref=${encodeURIComponent(reference || '')}`
      }
    })

    // On mémorise l'id de session Wave sur la ligne "donations" existante :
    // le webhook (server/api/dons/wave-webhook.post.js) en a besoin pour
    // relier l'événement reçu à ce don précis. Non bloquant si ça échoue —
    // voir le raisonnement équivalent dans orange.post.js.
    if (reference) {
      try {
        const admin = supabaseAdmin()
        await admin
          .from('donations')
          .update({ provider: 'wave', provider_reference: session.id })
          .eq('reference', reference)
      } catch (e) { /* non bloquant */ }
    }

    return { url: session.wave_launch_url, id: session.id }
  } catch (e) {
    throw createError({
      statusCode: 502,
      statusMessage: e?.data?.message || "Impossible de contacter Wave pour le moment."
    })
  }
})
