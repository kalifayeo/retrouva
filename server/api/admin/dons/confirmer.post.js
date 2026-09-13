// POST /api/admin/dons/confirmer  { id, statut }
// Remplace l'ancien changement de statut fait directement depuis le
// navigateur (supabase.from('donations').update(...) dans
// pages/admin/dons.vue) pour les seuls cas où un effet de bord serveur est
// nécessaire (envoi du reçu). Le rôle de l'appelant est vérifié côté
// serveur via son jeton, jamais via une donnée envoyée par le client — même
// principe que server/api/admin/inviter.post.js.
const statutsValides = ['en_attente', 'confirme', 'annule']

export default defineEventHandler(async (event) => {
  const utilisateur = await utilisateurDepuisRequete(event)
  const admin = supabaseAdmin()

  const { data: profilAppelant, error: erreurProfil } = await admin
    .from('profiles')
    .select('role')
    .eq('id', utilisateur.id)
    .maybeSingle()

  const estAdmin = ['administrateur', 'super_administrateur'].includes(profilAppelant?.role)
  if (erreurProfil || !estAdmin) {
    throw createError({ statusCode: 403, statusMessage: 'Action réservée aux administrateurs.' })
  }

  const body = await readBody(event)
  const id = String(body?.id || '')
  const statut = body?.statut

  if (!id) throw createError({ statusCode: 400, statusMessage: 'Identifiant de don manquant.' })
  if (!statutsValides.includes(statut)) throw createError({ statusCode: 400, statusMessage: 'Statut invalide.' })

  const payload = { statut }
  if (statut === 'confirme') {
    payload.confirmed_by = utilisateur.id
    payload.confirmed_at = new Date().toISOString()
  }

  const { error } = await admin.from('donations').update(payload).eq('id', id)
  if (error) throw createError({ statusCode: 500, statusMessage: "Impossible de mettre à jour le don." })

  // Best-effort : le don reste confirmé même si l'envoi du reçu échoue
  // (adresse absente, service e-mail non configuré...) — voir
  // server/utils/recuDon.js pour le détail des canaux essayés.
  let recu = null
  if (statut === 'confirme') {
    recu = await envoyerRecuDon(admin, id).catch((e) => ({ envoye: false, raison: e?.message }))
  }

  return { succes: true, recu }
})
