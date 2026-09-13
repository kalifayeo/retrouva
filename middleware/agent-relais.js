// Protège /agent-relais : réservé au compte "agent_relais" concerné (et,
// pour pouvoir dépanner/consulter, à administrateur/super_administrateur).
export default defineNuxtRouteMiddleware(() => {
  const { user, profile } = useAuth()

  if (!user.value) {
    return navigateTo('/connexion')
  }

  const roleOk = profile.value && ['agent_relais', 'administrateur', 'super_administrateur'].includes(profile.value.role)
  if (!roleOk) {
    return navigateTo('/')
  }
})
