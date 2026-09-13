// Envoi de SMS transactionnels (reçus de don) via une passerelle HTTP
// générique. Aucun fournisseur SMS ivoirien/international n'étant décidé
// pour ce projet, cette fonction reste volontairement "adaptable" : elle
// suppose une API acceptant { to, message } en JSON avec un jeton Bearer,
// ce qui couvre la majorité des passerelles (ex. votre propre agrégateur
// SMS, Orange SMS API, Twilio, etc.) moyennant l'URL exacte dans
// SMS_API_URL. Adaptez le corps de la requête ci-dessous si le format
// attendu par votre fournisseur diffère.
//
// Optionnel : tant que SMS_API_URL n'est pas renseignée, ne fait rien
// (voir server/utils/recuDon.js, qui appelle ceci en best-effort — un
// reçu par e-mail ou une notification in-app restent envoyés même si le
// SMS n'est pas configuré).
export const envoyerSms = async ({ to, message }) => {
  const config = useRuntimeConfig()
  const url = config.sms?.apiUrl
  const cleApi = config.sms?.apiKey
  const expediteur = config.sms?.sender

  if (!url) {
    return { envoye: false, raison: "SMS_API_URL non configurée sur le serveur." }
  }
  if (!to) {
    return { envoye: false, raison: 'Aucun numéro de téléphone destinataire.' }
  }

  try {
    await $fetch(url, {
      method: 'POST',
      headers: cleApi ? { Authorization: `Bearer ${cleApi}` } : undefined,
      body: { to, message, sender: expediteur || 'RETROUVA' }
    })
    return { envoye: true }
  } catch (e) {
    return { envoye: false, raison: e?.data?.message || e?.message || "Échec de l'envoi du SMS." }
  }
}
