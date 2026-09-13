// Protège une page : redirige vers /connexion si l'utilisateur n'est pas authentifié.
// Utilisation dans une page : definePageMeta({ middleware: 'auth' })
export default defineNuxtRouteMiddleware(() => {
  const { user } = useAuth()
  if (!user.value) {
    return navigateTo('/connexion')
  }
})
