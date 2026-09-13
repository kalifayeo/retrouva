// GET /api/dons/mes-dons/:id/attestation
// Le donateur ne peut télécharger que l'attestation de SON PROPRE don
// (vérifié ici via son jeton, jamais via une donnée du client) — voir
// server/utils/attestationPdf.js pour la génération du PDF, et
// pages/mes-dons.vue pour l'appel.
export default defineEventHandler(async (event) => {
  const utilisateur = await utilisateurDepuisRequete(event)
  const admin = supabaseAdmin()
  const id = getRouterParam(event, 'id')

  const { data: don } = await admin.from('donations').select('id, donor_user_id').eq('id', id).maybeSingle()
  if (!don) throw createError({ statusCode: 404, statusMessage: 'Don introuvable.' })
  if (don.donor_user_id !== utilisateur.id) {
    throw createError({ statusCode: 403, statusMessage: "Ce don n'appartient pas à ce compte." })
  }

  let pdfBytes
  try {
    pdfBytes = await genererAttestationPdf(admin, id)
  } catch (e) {
    throw createError({ statusCode: 400, statusMessage: e.message || "Impossible de générer l'attestation." })
  }

  setHeader(event, 'Content-Type', 'application/pdf')
  setHeader(event, 'Content-Disposition', `attachment; filename="attestation-don-${id}.pdf"`)
  return Buffer.from(pdfBytes)
})
