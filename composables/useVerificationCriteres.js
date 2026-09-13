// Questions de vérification privées, adaptées par catégorie d'objet.
// Ces éléments sont saisis par le déclarant d'une perte (lost_reports),
// stockés dans `criteres_verification` (jamais affichés publiquement),
// puis présentés au "trouveur" au moment de la vérification pour
// confirmer que le demandeur est bien le propriétaire réel.

const CRITERES = {
  telephone: [
    { key: 'couleur', label: 'Couleur exacte du téléphone', placeholder: 'Ex : noir mat' },
    { key: 'modele', label: 'Marque et modèle', placeholder: 'Ex : Samsung Galaxy A14' },
    { key: 'coque', label: 'Coque, étui ou pochette', placeholder: "Ex : coque transparente avec motif" },
    { key: 'ecran', label: "État de l'écran ou fond d'écran", placeholder: 'Ex : petite fissure en bas à droite' },
    { key: 'particularite', label: 'Autre signe distinctif', placeholder: 'Ex : autocollant au dos' }
  ],
  portefeuille: [
    { key: 'couleur', label: 'Couleur', placeholder: 'Ex : marron' },
    { key: 'marque', label: 'Marque (si visible)', placeholder: 'Ex : sans marque particulière' },
    { key: 'contenu', label: 'Contenu particulier (sans numéro complet)', placeholder: 'Ex : une photo, un ticket...' },
    { key: 'particularite', label: 'Signe distinctif', placeholder: 'Ex : coin usé, couture décousue' }
  ],
  cles: [
    { key: 'porte_cles', label: 'Porte-clés ou breloque', placeholder: 'Ex : porte-clés en forme de lion' },
    { key: 'nombre', label: 'Nombre de clés sur le trousseau', placeholder: 'Ex : 3 clés' },
    { key: 'particularite', label: 'Signe distinctif', placeholder: "Ex : une clé peinte en rouge" }
  ],
  autre: [
    { key: 'couleur', label: 'Couleur principale', placeholder: '' },
    { key: 'marque', label: 'Marque (si applicable)', placeholder: '' },
    { key: 'particularite', label: 'Signe distinctif précis', placeholder: 'Ex : rayure, autocollant, gravure...' }
  ]
}

// Documents officiels (CNI, permis, passeport, carte étudiante, etc.) :
// on ne demande jamais le numéro complet, seulement de quoi confirmer
// sans exposer la donnée sensible.
const CRITERES_DOCUMENT = [
  { key: 'nom_exact', label: "Nom et prénom exacts figurant sur le document", placeholder: 'Tel qu\'écrit sur le document' },
  { key: 'derniers_caracteres', label: 'Les 3 derniers chiffres/caractères du numéro', placeholder: 'Jamais le numéro complet' },
  { key: 'date', label: 'Date de naissance ou date d\'expiration', placeholder: 'JJ/MM/AAAA' },
  { key: 'particularite', label: 'Particularité visible', placeholder: 'Ex : coin plié, tampon, autocollant' }
]

const DOCUMENTS = ['cni', 'permis', 'cmu', 'passeport', 'electeur', 'professionnelle', 'etudiant', 'bancaire']

export const useVerificationCriteres = () => {
  const questionsPour = (typeId) => {
    if (DOCUMENTS.includes(typeId)) return CRITERES_DOCUMENT
    return CRITERES[typeId] || CRITERES.autre
  }

  return { questionsPour }
}
