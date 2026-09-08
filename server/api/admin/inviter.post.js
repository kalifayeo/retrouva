// POST /api/admin/inviter  { email, role }
// Invite un nouveau compte administrateur/modérateur par e-mail (template
// Supabase "Invite user"). Réservé aux super_administrateur : le rôle de
// l'appelant est vérifié côté serveur via son jeton, jamais via une donnée
// envoyée par le client.
const rolesInvitables = ['moderateur', 'administrateur', 'super_administrateur']

export default defineEventHandler(async (event) => {
  const utilisateur = await utilisateurDepuisRequete(event)
  const admin = supabaseAdmin()

  // Vérifie que l'appelant est bien super_administrateur (relit son profil
  // en base, ne fait jamais confiance à une info venue du client).
  const { data: profilAppelant, error: erreurProfil } = await admin
    .from('profiles')
    .select('role')
    .eq('id', utilisateur.id)
    .maybeSingle()

  if (erreurProfil || profilAppelant?.role !== 'super_administrateur') {
    throw createError({ statusCode: 403, statusMessage: 'Action réservée aux super-administrateurs.' })
  }

  const body = await readBody(event)
  const email = (body?.email || '').trim().toLowerCase()
  const role = body?.role

  if (!email || !email.includes('@')) {
    throw createError({ statusCode: 400, statusMessage: 'Adresse e-mail invalide.' })
  }
  if (!rolesInvitables.includes(role)) {
    throw createError({ statusCode: 400, statusMessage: 'Rôle invalide.' })
  }

  // Envoie l'invitation (template Supabase "Invite user"). Le rôle est
  // stocké dans les métadonnées ; le déclencheur handle_new_user() peut
  // les reprendre à la création du profil (voir supabase/schema.sql) —
  // à défaut, ajustez le rôle manuellement une fois le compte créé.
  const { data, error } = await admin.auth.admin.inviteUserByEmail(email, {
    data: { role, invite_par: utilisateur.id }
  })

  if (error) {
    throw createError({ statusCode: 500, statusMessage: error.message })
  }

  return { succes: true, utilisateur: data.user }
})
