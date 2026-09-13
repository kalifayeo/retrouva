// GET /api/dons/mtn-statut?ref=<referenceId>
// Consulte le statut d'une demande de paiement MTN Mobile Money initiée via
// POST /api/dons/mtn. Le front-end interroge cette route par intervalles le
// temps que le donateur valide (ou refuse) le prompt sur son téléphone.
// Réponses possibles : PENDING, SUCCESSFUL, FAILED.
export default defineEventHandler(async (event) => {
  const config = useRuntimeConfig()
  const referenceId = String(getQuery(event).ref || '')
  if (!referenceId) {
    throw createError({ statusCode: 400, statusMessage: 'Référence manquante.' })
  }

  try {
    const jeton = await obtenirJetonMtn(config)
    const statut = await $fetch(`${config.mtnMomo.baseUrl}/collection/v1_0/requesttopay/${referenceId}`, {
      headers: {
        Authorization: `Bearer ${jeton}`,
        'X-Target-Environment': config.mtnMomo.targetEnvironment,
        'Ocp-Apim-Subscription-Key': config.mtnMomo.subscriptionKey
      }
    })

    // Contrairement à Orange/Wave (notifications poussées par le
    // fournisseur), ce statut vient d'un appel que NOUS faisons nous-mêmes
    // à l'API MTN : il est donc déjà fiable, pas besoin de re-vérification
    // supplémentaire. On met simplement à jour la base une fois le
    // résultat final connu, avec idempotence via payment_webhook_events
    // pour ne pas ré-écrire à chaque appel de polling du front.
    if (statut.status === 'SUCCESSFUL' || statut.status === 'FAILED') {
      const admin = supabaseAdmin()
      const { error: erreurEvenement } = await admin
        .from('payment_webhook_events')
        .insert({
          provider: 'mtn',
          event_id: `${referenceId}:${statut.status}`,
          ip_source: ipDepuisRequete(event),
          payload: statut
        })
      if (!erreurEvenement) {
        const { data: don } = await admin
          .from('donations')
          .select('id, statut')
          .eq('provider_reference', referenceId)
          .eq('provider', 'mtn')
          .maybeSingle()

        if (don && don.statut !== 'confirme') {
          await admin
            .from('donations')
            .update({
              statut: statut.status === 'SUCCESSFUL' ? 'confirme' : 'annule',
              provider_transaction_id: statut.financialTransactionId || null,
              verified_at: new Date().toISOString()
            })
            .eq('id', don.id)

          if (statut.status === 'SUCCESSFUL') {
            // Best-effort : voir server/utils/recuDon.js.
            await envoyerRecuDon(admin, don.id).catch(() => {})
          }
        }
      }
    }

    return { statut: statut.status }
  } catch (e) {
    throw createError({
      statusCode: 502,
      statusMessage: e?.data?.message || "Impossible de vérifier le statut du paiement pour le moment."
    })
  }
})
