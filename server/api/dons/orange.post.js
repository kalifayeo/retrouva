// POST /api/dons/orange
// Initialise un paiement Orange Money (Web Payment / M Payment API) et
// renvoie l'URL de paiement vers laquelle rediriger le donateur : il y
// confirmera avec le mot de passe temporaire reçu par Orange Money USSD.
// Documentation : https://developer.orange.com/apis/om-webpay
export default defineEventHandler(async (event) => {
  const config = useRuntimeConfig()
  if (!config.orangeMoney?.clientId || !config.orangeMoney?.clientSecret || !config.orangeMoney?.merchantKey) {
    throw createError({
      statusCode: 500,
      statusMessage: "Le paiement Orange Money n'est pas configuré sur le serveur."
    })
  }

  const body = await readBody(event)
  const montant = Number(body?.montant)
  if (!Number.isFinite(montant) || montant <= 0) {
    throw createError({ statusCode: 400, statusMessage: 'Montant invalide.' })
  }

  const origine = getRequestURL(event).origin
  // order_id = la référence du don (DON-XXXX), déjà enregistrée en base
  // par POST /api/dons/creer avant cet appel : c'est ce qui permet au
  // webhook et à la vérification de retrouver la bonne ligne "donations".
  const orderId = String(body?.reference || `DON-${Date.now()}`).slice(0, 64)
  const montantArrondi = Math.round(montant)

  try {
    const jeton = await obtenirJetonOrange(config)
    const paiement = await $fetch('https://api.orange.com/orange-money-webpay/ci/v1/webpayment', {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${jeton}`,
        'Content-Type': 'application/json',
        Accept: 'application/json'
      },
      body: {
        merchant_key: config.orangeMoney.merchantKey,
        // "OUV" est le code devise attendu par l'API Orange Money pour la
        // zone UEMOA (FCFA), quel que soit le libellé affiché au donateur.
        currency: 'OUV',
        order_id: orderId,
        amount: montantArrondi,
        return_url: `${origine}/don?paiement=succes&methode=orange&ref=${encodeURIComponent(orderId)}`,
        cancel_url: `${origine}/don?paiement=annule&methode=orange&ref=${encodeURIComponent(orderId)}`,
        notif_url: `${origine}/api/dons/orange-notification`,
        lang: 'fr',
        reference: 'RETROUVA'
      }
    })

    // On mémorise order_id + pay_token + montant sur la ligne "donations"
    // existante : la vérification (webhook et /api/dons/verifier) en aura
    // besoin. Ne bloque jamais l'affichage du lien de paiement si cette
    // écriture échoue (le donateur ne doit pas payer dans le vide, mais un
    // souci ici resterait rattrapable manuellement par l'équipe).
    try {
      const admin = supabaseAdmin()
      await admin
        .from('donations')
        .update({
          provider: 'orange',
          provider_reference: orderId,
          provider_metadata: { pay_token: paiement.pay_token, montant: montantArrondi }
        })
        .eq('reference', orderId)
    } catch (e) { /* voir commentaire ci-dessus : non bloquant */ }

    return { url: paiement.payment_url, token: paiement.pay_token }
  } catch (e) {
    throw createError({
      statusCode: 502,
      statusMessage: e?.data?.message || "Impossible de contacter Orange Money pour le moment."
    })
  }
})
