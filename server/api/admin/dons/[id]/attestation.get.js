// GET /api/admin/dons/:id/attestation
// Réservé aux administrateurs — permet de générer/télécharger l'attestation
// d'un don confirmé même si le donateur n'était pas connecté (dons
// entreprise renseignés par téléphone/en personne, par exemple), ou de la
// renvoyer si le donateur l'a perdue.
export default defineEventHandler(async (event) => {
  const utilisateur = await utilisateurDepuisRequete(event)
  const admin = supabaseAdmin()

  const { data: profilAppelant } = await admin
    .from('profiles')
    .select('role')
    .eq('id', utilisateur.id)
    .maybeSingle()

  if (!['administrateur', 'super_administrateur'].includes(profilAppelant?.role)) {
    throw createError({ statusCode: 403, statusMessage: 'Action réservée aux administrateurs.' })
  }

  const id = getRouterParam(event, 'id')

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
