export const useObjectTypes = () => {
  const objectTypes = [
    { id: 'cni', label: "Carte d'identité", icon: 'card', image: '/objets/cni.webp' },
    { id: 'permis', label: 'Permis de conduire', icon: 'card', image: '/objets/permis.jpg' },
    { id: 'cmu', label: 'Carte CMU', icon: 'card', image: '/objets/cmu.webp' },
    { id: 'passeport', label: 'Passeport', icon: 'card', image: '/objets/passeport.jpg' },
    { id: 'electeur', label: "Carte d'électeur", icon: 'card', image: '/objets/electeur.webp' },
    { id: 'professionnelle', label: 'Carte professionnelle', icon: 'card', image: '/objets/professionnelle.jpg' },
    { id: 'etudiant', label: 'Carte étudiant', icon: 'card', image: '/objets/etudiant.jpg' },
    { id: 'bancaire', label: 'Carte bancaire', icon: 'card', image: '/objets/bancaire.jpg' },
    { id: 'telephone', label: 'Téléphone', icon: 'card', image: '/objets/telephone.jpg' },
    { id: 'portefeuille', label: 'Portefeuille', icon: 'card', image: '/objets/portefeuille.webp' },
    { id: 'cles', label: 'Clés', icon: 'card', image: '/objets/cles.jpg' },
    { id: 'autre', label: 'Autre objet', icon: 'card', image: '/objets/autre.webp' }
  ]

  const villes = [
    'Abidjan', 'Bouaké', 'Daloa', 'Korhogo', 'San-Pédro', 'Yamoussoukro',
    'Divo', 'Gagnoa', 'Man', 'Abengourou', 'Anyama', 'Grand-Bassam'
  ]

  const communesAbidjan = [
    'Abobo', 'Adjamé', 'Attécoubé', 'Cocody', 'Koumassi', 'Marcory',
    'Plateau', 'Port-Bouët', 'Treichville', 'Yopougon', 'Bingerville', 'Songon'
  ]

  return { objectTypes, villes, communesAbidjan }
}
