// POST /api/compte/supprimer
// Supprime définitivement le compte de l'utilisateur qui fait la requête
// (jamais celui d'un autre compte — l'identité vient uniquement du jeton
// d'accès vérifié côté serveur, jamais d'un champ envoyé par le client).
// Le profil et toutes les données liées (déclarations, messages...) sont
// supprimés en cascade au niveau de la base (voir supabase/schema.sql).
export default defineEventHandler(async (event) => {
  const utilisateur = await utilisateurDepuisRequete(event)

  const admin = supabaseAdmin()
  const { error } = await admin.auth.admin.deleteUser(utilisateur.id)

  if (error) {
    throw createError({ statusCode: 500, statusMessage: error.message })
  }

  return { succes: true }
})
