// Mode maintenance — activable/désactivable depuis /admin/contenu (section
// "Mode maintenance"), stocké dans la table site_settings (clé
// 'maintenance_mode' = 'on' | 'off'). Le préfixe "00." force ce middleware
// à s'exécuter avant les autres ; le suffixe ".global" le fait tourner sur
// toutes les routes sans avoir à l'ajouter page par page.
//
// Exceptions volontaires :
// - /admin/** reste toujours accessible (l'équipe doit pouvoir désactiver
//   la maintenance depuis l'administration).
// - /maintenance elle-même, pour éviter une boucle de redirection infinie.
// - Les comptes administrateur/modérateur peuvent continuer à naviguer sur
//   le site public pendant la maintenance, pour vérifier le rendu réel.
export default defineNuxtRouteMiddleware(async (to) => {
  if (to.path.startsWith('/admin') || to.path === '/maintenance') return

  const configured = useSupabaseConfigured()
  if (!configured) return // Supabase non configuré : on n'entrave pas la navigation locale

  const supabase = useSupabase()
  const { profile } = useAuth()
  const rolesExemptes = ['administrateur', 'super_administrateur', 'moderateur']
  if (profile.value && rolesExemptes.includes(profile.value.role)) return

  // useState met en cache la valeur pour la durée de la session de
  // navigation : un seul appel réseau, pas une requête à chaque changement
  // de page. La valeur repart à `null` (non chargée) à chaque rechargement
  // complet du site.
  const maintenanceActive = useState('retrouva_maintenance_active', () => null)
  const maintenanceMessage = useState('retrouva_maintenance_message_cache', () => '')

  if (maintenanceActive.value === null) {
    try {
      const { data } = await supabase
        .from('site_settings')
        .select('cle, valeur')
        .in('cle', ['maintenance_mode', 'maintenance_message'])

      const reglages = {}
      for (const ligne of data || []) reglages[ligne.cle] = ligne.valeur

      maintenanceActive.value = reglages.maintenance_mode === 'on'
      maintenanceMessage.value = reglages.maintenance_message || ''
    } catch {
      // En cas d'erreur réseau/Supabase, on n'empêche pas la navigation :
      // mieux vaut un site accessible qu'un site bloqué par erreur.
      maintenanceActive.value = false
    }
  }

  if (maintenanceActive.value) {
    return navigateTo('/maintenance')
  }
})
