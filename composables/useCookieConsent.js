// Gestion du consentement aux cookies non essentiels (pop-up, vidéo
// d'accueil, écran d'onboarding). Les cookies strictement nécessaires au
// fonctionnement (session de connexion, préférence de thème, identifiant de
// conversation support) ne demandent pas de consentement et restent actifs.
//
// État persistant dans localStorage sous forme :
//   { necessaire: true, fonctionnel: boolean, date: '2026-...' }
// - null / absent  => aucun choix encore fait (bannière affichée, comportement
//   par défaut identique à avant pour ne rien casser en attendant la décision)
// - fonctionnel:true  => cookies de confort autorisés (comportement normal)
// - fonctionnel:false => l'utilisateur a explicitement refusé : les
//   composants concernés (pop-up, vidéo, onboarding) ne s'affichent pas.
const CLE_STOCKAGE = 'retrouva_cookies_consentement'

export const useCookieConsent = () => {
  const consentement = useState('retrouva_consentement_cookies', () => undefined)

  const charger = () => {
    if (typeof window === 'undefined') return
    if (consentement.value !== undefined) return
    try {
      const brut = localStorage.getItem(CLE_STOCKAGE)
      consentement.value = brut ? JSON.parse(brut) : null
    } catch {
      consentement.value = null
    }
  }

  const enregistrer = ({ fonctionnel }) => {
    const valeur = { necessaire: true, fonctionnel: !!fonctionnel, date: new Date().toISOString() }
    consentement.value = valeur
    if (typeof window !== 'undefined') {
      try { localStorage.setItem(CLE_STOCKAGE, JSON.stringify(valeur)) } catch { /* stockage indisponible */ }
    }
  }

  const toutAccepter = () => enregistrer({ fonctionnel: true })
  const toutRefuser = () => enregistrer({ fonctionnel: false })

  // Permet de revenir sur son choix (bouton "Gérer mes cookies" sur /cookies)
  const reinitialiser = () => {
    consentement.value = null
    if (typeof window !== 'undefined') {
      try { localStorage.removeItem(CLE_STOCKAGE) } catch { /* stockage indisponible */ }
    }
  }

  // true seulement si l'utilisateur a explicitement refusé les cookies de
  // confort — tant qu'aucun choix n'est fait, on laisse le comportement par
  // défaut (identique à avant l'ajout du bandeau) pour ne rien casser.
  const fonctionnelRefuse = computed(() => consentement.value?.fonctionnel === false)
  const choixFait = computed(() => consentement.value !== null && consentement.value !== undefined)

  return { consentement, charger, enregistrer, toutAccepter, toutRefuser, reinitialiser, fonctionnelRefuse, choixFait }
}
