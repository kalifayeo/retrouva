// Protège /partenaire : réservé au compte "partenaire" concerné (et, pour
// pouvoir dépanner/consulter, à administrateur/super_administrateur). Un
// visiteur non connecté est renvoyé vers /connexion ; un compte connecté
// mais du mauvais rôle est renvoyé vers l'accueil.
export default defineNuxtRouteMiddleware(() => {
  const { user, profile } = useAuth()

  if (!user.value) {
    return navigateTo('/connexion')
  }

  const roleOk = profile.value && ['partenaire', 'administrateur', 'super_administrateur'].includes(profile.value.role)
  if (!roleOk) {
    return navigateTo('/')
  }
})
