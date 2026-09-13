// État de la connexion réseau de l'appareil, basé sur l'API Network
// Information (exposée ici via VueUse, déjà présent dans le projet) et sur
// les évènements online/offline natifs du navigateur.
//
// Utilisé pour :
//  - afficher une bannière discrète quand la connexion est lente (voir
//    components/ConnexionBanniere.vue) ;
//  - afficher un état "hors ligne" plein écran quand l'appareil n'a plus du
//    tout de connexion (voir components/HorsLigneContenu.vue, monté
//    globalement dans app.vue, et pages/hors-ligne.vue).
//
// Remarque : `effectiveType` et `downlink` ne sont fournis que par certains
// navigateurs (Chrome/Edge/Android notamment). Sur les navigateurs qui ne
// les exposent pas (Safari/iOS), seul l'état en ligne/hors ligne est fiable
// — la détection de connexion lente y est simplement désactivée plutôt que
// de donner un faux résultat.
export const useConnexionReseau = () => {
  const { isOnline, effectiveType, downlink, saveData } = useNetwork()

  // Connexion jugée "lente" si le navigateur rapporte un type 2G/slow-2G,
  // ou un débit descendant estimé sous ~0.6 Mbps. Jamais vrai hors ligne :
  // dans ce cas c'est l'état "hors ligne" qui prend le relais, pas la
  // bannière de connexion lente.
  const estLente = computed(() => {
    if (!isOnline.value) return false
    if (effectiveType.value && ['slow-2g', '2g'].includes(effectiveType.value)) return true
    if (typeof downlink.value === 'number' && downlink.value > 0 && downlink.value < 0.6) return true
    return false
  })

  return {
    estEnLigne: isOnline,
    estLente,
    typeConnexion: effectiveType,
    debit: downlink,
    modeEconomieDonnees: saveData
  }
}
