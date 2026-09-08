// Système de statuts unifié pour les déclarations (perdu / trouvé).
// Centralise le mapping "statut technique -> présentation" (emoji, libellé,
// couleur, description) pour éviter de dupliquer cette logique dans chaque
// page (dashboard, mes-recherches, mes-objets-trouves, résultats...).
//
// Repose sur l'enum existant `declaration_statut` de la base :
// 'active' | 'correspondance' | 'en_verification' | 'restituee' | 'expiree' | 'archivee'
// On garde ces valeurs telles quelles côté base — on n'ajoute ici qu'une
// couche d'affichage, pour ne rien casser côté backend/RLS/triggers.

export const useStatuts = () => {
  // Statuts pour un objet PERDU ("recherche")
  const statutsPerdu = {
    active: {
      emoji: '🔎',
      label: 'Recherche en cours',
      description: 'RETROUVA surveille les nouvelles déclarations pouvant correspondre à votre objet.',
      badge: 'badge-orange'
    },
    correspondance: {
      emoji: '🎯',
      label: 'Correspondance potentielle',
      description: 'Une déclaration pourrait correspondre à votre objet. Vérifiez-la dès maintenant.',
      badge: 'badge-green'
    },
    en_verification: {
      emoji: '🔐',
      label: 'Vérification en cours',
      description: 'Confirmez des détails que seul le propriétaire peut connaître pour sécuriser la remise.',
      badge: 'badge-orange'
    },
    restituee: {
      emoji: '✅',
      label: 'Objet récupéré',
      description: "L'objet a été remis avec succès à son propriétaire.",
      badge: 'badge-green'
    },
    expiree: {
      emoji: '⚠️',
      label: 'Déclaration expirée',
      description: "Aucune correspondance n'a été trouvée dans le délai prévu.",
      badge: 'badge bg-forest-50 text-forest-400'
    },
    archivee: {
      emoji: '🚫',
      label: 'Déclaration archivée',
      description: 'Cette déclaration a été clôturée.',
      badge: 'badge bg-forest-50 text-forest-400'
    }
  }

  // Statuts pour un objet TROUVÉ
  const statutsTrouve = {
    active: {
      emoji: '🟢',
      label: 'Objet déclaré',
      description: 'Retrouva recherche actuellement le propriétaire de cet objet.',
      badge: 'badge-green'
    },
    correspondance: {
      emoji: '🎯',
      label: 'Correspondance potentielle',
      description: 'Un propriétaire potentiel a été identifié pour cet objet.',
      badge: 'badge-green'
    },
    en_verification: {
      emoji: '🔐',
      label: 'Vérification en cours',
      description: 'Le demandeur doit confirmer des détails précis avant la remise.',
      badge: 'badge-orange'
    },
    restituee: {
      emoji: '📦',
      label: 'Objet remis',
      description: "L'objet a été remis à son propriétaire. Merci pour votre aide !",
      badge: 'badge-green'
    },
    expiree: {
      emoji: '⚠️',
      label: 'Déclaration expirée',
      description: "Aucun propriétaire n'a été identifié dans le délai prévu.",
      badge: 'badge bg-forest-50 text-forest-400'
    },
    archivee: {
      emoji: '🚫',
      label: 'Déclaration archivée',
      description: 'Cette déclaration a été clôturée.',
      badge: 'badge bg-forest-50 text-forest-400'
    }
  }

  // Étapes du parcours affichées en frise (utilisées en page de suivi/détail)
  const parcoursPerdu = ['active', 'correspondance', 'en_verification', 'restituee']
  const parcoursTrouve = ['active', 'correspondance', 'en_verification', 'restituee']

  const infoStatut = (statut, type = 'perdu') => {
    const table = type === 'trouve' ? statutsTrouve : statutsPerdu
    return table[statut] || { emoji: '•', label: statut, description: '', badge: 'badge' }
  }

  const etapeIndex = (statut, type = 'perdu') => {
    const parcours = type === 'trouve' ? parcoursTrouve : parcoursPerdu
    const i = parcours.indexOf(statut)
    return i === -1 ? 0 : i
  }

  const scoreLabel = (score) => {
    if (score >= 80) return { label: 'Forte correspondance', classe: 'badge-green' }
    if (score >= 50) return { label: 'Correspondance moyenne', classe: 'badge-orange' }
    return { label: 'Correspondance faible', classe: 'badge bg-forest-50 text-forest-400' }
  }

  return { statutsPerdu, statutsTrouve, parcoursPerdu, parcoursTrouve, infoStatut, etapeIndex, scoreLabel }
}
