// Protège les pages /admin/** (hors /admin/connexion elle-même).
// Accessible aux comptes 'administrateur' et 'super_administrateur' sur
// tout /admin/**, et en plus aux 'moderateur' sur le sous-ensemble de
// pages défini dans useAdminPermissions.js (signalements, support,
// déclarations). Toute personne non autorisée est renvoyée vers la page
// de connexion dédiée à l'administration (distincte du site public).
export default defineNuxtRouteMiddleware((to) => {
  if (to.path === '/admin/connexion') return

  const { user, profile } = useAuth()

  if (!user.value) {
    return navigateTo('/admin/connexion')
  }

  const roleOk = peutAccederPage(profile.value?.role, to.path)
  if (!roleOk) {
    return navigateTo('/admin/connexion?denied=1')
  }
})
