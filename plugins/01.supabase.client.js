import { createClient } from '@supabase/supabase-js'

export default defineNuxtPlugin(() => {
  const config = useRuntimeConfig()
  const url = config.public.supabaseUrl
  const key = config.public.supabaseAnonKey

  const configured = !!url && !!key && url.startsWith('http')

  if (!configured) {
    // Évite un crash total (page 500) quand .env n'est pas encore renseigné.
    // Voir README.md section "Installation initiale".
    // eslint-disable-next-line no-console
    console.warn(
      '[RETROUVA] Supabase non configuré : créez un fichier .env à partir de .env.example ' +
      'et renseignez SUPABASE_URL et SUPABASE_ANON_KEY, puis relancez "npm run dev".'
    )
  }

  const supabase = configured
    ? createClient(url, key, {
        auth: {
          persistSession: true,
          autoRefreshToken: true,
          // Nécessaire pour que le clic sur le lien reçu par e-mail connecte
          // réellement l'utilisateur (le token est présent dans l'URL de retour).
          detectSessionInUrl: true
        }
      })
    : null

  return {
    provide: {
      supabase,
      supabaseConfigured: configured
    }
  }
})
