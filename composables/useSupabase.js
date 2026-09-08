export const useSupabase = () => {
  const { $supabase } = useNuxtApp()
  return $supabase
}

// À utiliser pour afficher un message clair plutôt qu'un plantage
// quand .env n'a pas encore été renseigné.
export const useSupabaseConfigured = () => {
  const { $supabaseConfigured } = useNuxtApp()
  return !!$supabaseConfigured
}
