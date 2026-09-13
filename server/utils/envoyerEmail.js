// Envoi d'e-mails transactionnels (reçus de don) via l'API Resend
// (resend.com — API HTTP simple, sans SDK nécessaire). Optionnel : tant
// que RESEND_API_KEY n'est pas renseignée dans .env, cette fonction ne
// fait rien et remonte simplement "non configuré", pour ne jamais faire
// planter le flux de don si l'admin n'a pas encore mis en place l'envoi
// d'e-mails (voir server/utils/recuDon.js, qui appelle ceci en best-effort).
//
// Pourquoi Resend et pas Supabase Auth (déjà utilisé pour les codes de
// vérification) : les e-mails d'authentification Supabase ne peuvent pas
// être détournés pour un contenu libre (reçu de don, montant, etc.) — il
// faut un envoi transactionnel classique, indépendant de l'auth.
export const envoyerEmail = async ({ to, subject, html, text }) => {
  const config = useRuntimeConfig()
  const cleApi = config.resend?.apiKey
  const expediteur = config.resend?.from

  if (!cleApi || !expediteur) {
    return { envoye: false, raison: "RESEND_API_KEY ou RESEND_FROM_EMAIL non configurée sur le serveur." }
  }
  if (!to) {
    return { envoye: false, raison: 'Aucune adresse e-mail destinataire.' }
  }

  try {
    await $fetch('https://api.resend.com/emails', {
      method: 'POST',
      headers: { Authorization: `Bearer ${cleApi}` },
      body: { from: expediteur, to: [to], subject, html, text }
    })
    return { envoye: true }
  } catch (e) {
    return { envoye: false, raison: e?.data?.message || e?.message || "Échec de l'envoi de l'e-mail." }
  }
}
