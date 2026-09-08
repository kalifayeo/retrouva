import { createClient } from '@supabase/supabase-js'

/**
 * Client Supabase "admin" — utilise la clé service_role, qui contourne les
 * policies RLS et peut agir sur n'importe quel compte. Ne JAMAIS importer
 * ceci depuis un fichier accessible au navigateur (composables/, pages/,
 * components/) : uniquement depuis server/api/**.
 */
export const supabaseAdmin = () => {
  const config = useRuntimeConfig()
  if (!config.supabaseServiceRoleKey) {
    throw createError({
      statusCode: 500,
      statusMessage: "SUPABASE_SERVICE_ROLE_KEY n'est pas configurée sur le serveur."
    })
  }
  return createClient(config.public.supabaseUrl, config.supabaseServiceRoleKey, {
    auth: { autoRefreshToken: false, persistSession: false }
  })
}

/**
 * Vérifie le jeton d'accès envoyé par le client (header Authorization:
 * Bearer <token>) et retourne l'utilisateur correspondant. Lève une erreur
 * 401 si le jeton est absent ou invalide — ne fait JAMAIS confiance à un
 * identifiant envoyé directement par le client dans le corps de la requête.
 */
export const utilisateurDepuisRequete = async (event) => {
  const authHeader = getHeader(event, 'authorization') || ''
  const token = authHeader.replace(/^Bearer\s+/i, '')
  if (!token) {
    throw createError({ statusCode: 401, statusMessage: 'Non authentifié.' })
  }
  const admin = supabaseAdmin()
  const { data, error } = await admin.auth.getUser(token)
  if (error || !data?.user) {
    throw createError({ statusCode: 401, statusMessage: 'Session invalide ou expirée.' })
  }
  return data.user
}
