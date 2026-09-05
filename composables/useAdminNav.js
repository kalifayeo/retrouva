// Liste complète des liens du menu admin. On filtre ensuite selon le rôle
// du compte connecté (voir useAdminPermissions.js) : un modérateur, par
// exemple, ne verra que les liens vers les pages qu'il a réellement le
// droit d'ouvrir — ça évite d'afficher des liens qui renverraient de
// toute façon vers "accès refusé".
const navComplet = [
  { to: '/admin', label: "Vue d'ensemble", icon: 'card', exact: true },
  { to: '/admin/utilisateurs', label: 'Utilisateurs', icon: 'user' },
  { to: '/admin/declarations', label: 'Déclarations', icon: 'search' },
  { to: '/admin/correspondances', label: 'Correspondances', icon: 'handshake' },
  { to: '/admin/signalements', label: 'Signalements', icon: 'bell' },
  { to: '/admin/partenaires', label: 'Partenaires', icon: 'handshake' },
  { to: '/admin/dons', label: 'Dons', icon: 'gift' },
  { to: '/admin/support', label: 'Support technique', icon: 'chat' },
  { to: '/admin/contenu', label: 'Contenu du site', icon: 'card' },
  { to: '/admin/bannieres', label: 'Bannières & pub', icon: 'megaphone' },
  { to: '/admin/popups', label: 'Pop-up', icon: 'bell' },
  { to: '/admin/evenements', label: 'Événements', icon: 'clock' },
  { to: '/admin/introduction', label: 'Introduction du site', icon: 'video' }
]

export const useAdminNav = () => {
  const { profile } = useAuth()
  const role = profile.value?.role
  return navComplet.filter((item) => peutAccederPage(role, item.to))
}
