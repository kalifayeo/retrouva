// POST /api/dons/orange-notification
// Reçu par les serveurs Orange (paramètre "notif_url" envoyé lors de la
// création du paiement) une fois la transaction traitée.
//
// IMPORTANT — pourquoi on ne fait JAMAIS confiance directement à ce
// webhook : Orange n'y joint pas de signature vérifiable, et n'importe
// qui connaissant (ou devinant) cette URL pourrait poster un faux corps
// "status: SUCCESS" pour un montant qu'il n'a jamais payé. On ne l'utilise
// donc que comme un DÉCLENCHEUR : dès réception, on rappelle nous-mêmes
// l'API officielle "Transaction Status" d'Orange (serveur à serveur, avec
// notre jeton OAuth) pour connaître le VRAI statut, et c'est cette
// réponse-là — jamais le corps du webhook — qui détermine si le don est
// marqué "confirme".
export default defineEventHandler(async (event) => {
  const config = useRuntimeConfig()
  const body = await readBody(event).catch(() => ({}))
  const orderId = String(body?.order_id || '').slice(0, 64)

  // Orange n'attend qu'un 200 rapide ; on répond tout de suite après avoir
  // lancé la vérification pour éviter un retry inutile de leur côté, mais
  // on ne traite jamais silencieusement une notification sans order_id.
  if (!orderId) {
    return { statut: 'ok' }
  }

  const admin = supabaseAdmin()

  try {
    const { data: don } = await admin
      .from('donations')
      .select('id, statut, provider_metadata')
      .eq('provider_reference', orderId)
      .eq('provider', 'orange')
      .maybeSingle()

    if (!don || don.statut === 'confirme') {
      // Don introuvable, ou déjà confirmé (idempotence) : rien à refaire.
      return { statut: 'ok' }
    }

    const payToken = don.provider_metadata?.pay_token
    const montant = don.provider_metadata?.montant
    if (!payToken || !montant) return { statut: 'ok' }

    // Vérification officielle — voir server/utils/orangeMoney.js
    const { statut, txnid } = await verifierStatutOrange(config, { orderId, amount: montant, payToken })

    // Idempotence : si cet événement (order_id + statut Orange) a déjà été
    // traité, on ne le traite pas une seconde fois. La contrainte unique
    // (provider, event_id) fait échouer l'insertion en cas de doublon.
    const { error: erreurEvenement } = await admin
      .from('payment_webhook_events')
      .insert({
        provider: 'orange',
        event_id: `${orderId}:${statut}`,
        ip_source: ipDepuisRequete(event),
        payload: body
      })
    if (erreurEvenement) return { statut: 'ok' } // doublon déjà traité, on s'arrête là

    if (statut === 'SUCCESS') {
      await admin
        .from('donations')
        .update({ statut: 'confirme', provider_transaction_id: txnid, verified_at: new Date().toISOString() })
        .eq('id', don.id)
      // Best-effort : voir server/utils/recuDon.js.
      await envoyerRecuDon(admin, don.id).catch(() => {})
    } else if (statut === 'FAILED' || statut === 'EXPIRED') {
      await admin
        .from('donations')
        .update({ statut: 'annule', verified_at: new Date().toISOString() })
        .eq('id', don.id)
    }
    // 'INITIATED' / 'PENDING' : on ne change rien, une prochaine
    // notification (ou l'admin manuellement) confirmera plus tard.
  } catch (e) {
    // On ne renvoie jamais d'erreur à Orange pour ça (ils réessaieraient
    // en boucle) ; l'équipe RETROUVA garde de toute façon la main pour
    // confirmer manuellement depuis /admin/dons en dernier recours.
  }

  return { statut: 'ok' }
})
