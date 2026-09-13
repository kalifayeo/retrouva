// Envoie le reçu de don une fois qu'un don passe au statut "confirme" —
// appelé à la fois par la confirmation manuelle admin
// (server/api/admin/dons/confirmer.post.js) et par les webhooks/statuts de
// paiement automatiques (wave-webhook, orange-notification, mtn-statut).
//
// Best-effort et non bloquant à chaque étape : l'absence d'e-mail du
// donateur, ou l'absence de configuration Resend/SMS/FCM, ne doit jamais
// empêcher la confirmation du don elle-même. Si le donateur est connecté
// (donor_user_id), il reçoit toujours au minimum une notification in-app
// (table "notifications", déjà utilisée pour les correspondances/messages
// — visible sur /notifications et dans la cloche du header), même si
// aucun service d'e-mail/SMS/push n'est configuré sur le serveur.
export const envoyerRecuDon = async (admin, donId) => {
  const { data: don, error } = await admin
    .from('donations')
    .select('*, payment_methods(nom)')
    .eq('id', donId)
    .maybeSingle()

  if (error || !don) return { envoye: false, raison: 'Don introuvable.' }

  const montantAffiche = `${Number(don.montant).toLocaleString('fr-FR')} FCFA`
  const nomAffiche = don.type_donateur === 'entreprise' && don.raison_sociale
    ? don.raison_sociale
    : (don.nom_donateur || 'Cher donateur')

  const sujet = 'Merci pour votre don à RETROUVA 🙏'
  const texte = `Bonjour ${nomAffiche},\n\nNous avons bien reçu et confirmé votre don de ${montantAffiche} `
    + `(référence ${don.reference}${don.payment_methods?.nom ? `, via ${don.payment_methods.nom}` : ''}).\n\n`
    + `Toute l'équipe RETROUVA vous remercie pour votre soutien.\n\n— RETROUVA`
  const html = `<p>Bonjour ${nomAffiche},</p>`
    + `<p>Nous avons bien reçu et confirmé votre don de <strong>${montantAffiche}</strong> `
    + `(référence <strong>${don.reference}</strong>${don.payment_methods?.nom ? `, via ${don.payment_methods.nom}` : ''}).</p>`
    + (don.type_donateur === 'entreprise'
        ? `<p>Une attestation de don peut être générée à tout moment à votre demande auprès de notre équipe.</p>`
        : '')
    + `<p>Toute l'équipe RETROUVA vous remercie pour votre soutien.</p><p>— RETROUVA</p>`

  const resultats = { email: null, sms: null, push: null, notificationInApp: false }

  // --- E-mail (si une adresse a été fournie) ---
  if (don.email_donateur) {
    resultats.email = await envoyerEmail({ to: don.email_donateur, subject: sujet, html, text: texte })
  }

  // --- SMS (si un numéro a été fourni) ---
  if (don.telephone_donateur) {
    resultats.sms = await envoyerSms({
      to: don.telephone_donateur,
      message: `RETROUVA : merci pour votre don de ${montantAffiche} (réf. ${don.reference}), bien reçu et confirmé.`
    })
  }

  // --- Notification in-app + push (si le donateur était connecté) ---
  if (don.donor_user_id) {
    await admin.from('notifications').insert({
      user_id: don.donor_user_id,
      titre: '🙏 Don confirmé — merci !',
      corps: `Votre don de ${montantAffiche} a bien été confirmé par notre équipe.`,
      type: 'don',
      lien: '/mes-dons'
    })
    resultats.notificationInApp = true

    const { data: appareils } = await admin
      .from('push_tokens')
      .select('jeton')
      .eq('user_id', don.donor_user_id)

    if (appareils?.length) {
      const push = await envoyerPush({
        jetons: appareils.map((a) => a.jeton),
        titre: '🙏 Don confirmé — merci !',
        corps: `Votre don de ${montantAffiche} a bien été confirmé.`,
        lien: '/mes-dons'
      })
      resultats.push = push

      if (push.jetonsInvalides?.length) {
        await admin.from('push_tokens').delete().in('jeton', push.jetonsInvalides)
      }
    }
  }

  const erreurs = [resultats.email, resultats.sms].filter((r) => r && r.envoye === false).map((r) => r.raison)
  await admin
    .from('donations')
    .update({
      recu_envoye_at: new Date().toISOString(),
      recu_erreur: erreurs.length ? erreurs.join(' · ') : null
    })
    .eq('id', don.id)

  return { envoye: true, details: resultats }
}
