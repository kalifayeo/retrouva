// POST /api/admin/dons/renvoyer-recu  { id }
// Permet à l'admin de renvoyer manuellement le reçu (e-mail/SMS/notification
// in-app) d'un don déjà confirmé — utile si le donateur a signalé ne rien
// avoir reçu, ou si l'e-mail a été ajouté après coup sur la fiche du don.
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

  const body = await readBody(event)
  const id = String(body?.id || '')
  if (!id) throw createError({ statusCode: 400, statusMessage: 'Identifiant de don manquant.' })

  const { data: don } = await admin.from('donations').select('id, statut').eq('id', id).maybeSingle()
  if (!don) throw createError({ statusCode: 404, statusMessage: 'Don introuvable.' })
  if (don.statut !== 'confirme') {
    throw createError({ statusCode: 400, statusMessage: "Ce don n'est pas encore confirmé." })
  }

  const recu = await envoyerRecuDon(admin, id)
  return { succes: true, recu }
})
