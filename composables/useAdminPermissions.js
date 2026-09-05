/**
 * Permissions fines du panneau d'administration, page par page.
 *
 * Jusqu'ici, seuls 'administrateur' et 'super_administrateur' avaient accès
 * à /admin/**, en tout ou rien (voir middleware/admin.js). Ce fichier
 * introduit un rôle supplémentaire, 'moderateur', qui ne voit qu'un sous-
 * ensemble des pages (signalements, support, déclarations en lecture et
 * masquage), sans toucher aux dons, au contenu du site, aux bannières ou
 * aux rôles des autres comptes.
 *
 * Important : ceci ne remplace PAS les policies RLS côté Supabase, qui
 * restent la vraie barrière de sécurité (voir supabase/migration_23_*.sql).
 * Cette liste ne fait que décider ce qui s'affiche/est accessible côté
 * Nuxt, pour le confort d'usage.
 */

// Rôles qui ont accès à /admin/** sous une forme ou une autre (le reste
// des rôles — utilisateur, utilisateur_verifie, partenaire, agent_relais —
// n'a jamais d'accès au panneau admin et n'apparaît pas ici).
export const rolesStaffAdmin = ['administrateur', 'super_administrateur', 'moderateur']

// Rôles autorisés par défaut quand une page n'est pas listée explicitement
// ci-dessous : comportement identique à l'ancien middleware (avant l'ajout
// du rôle "moderateur").
export const rolesParDefaut = ['administrateur', 'super_administrateur']

// Exceptions : pages accessibles à d'autres rôles que administrateur/
// super_administrateur. Toute page absente de cette liste retombe sur
// `rolesParDefaut`.
export const permissionsParPage = {
  '/admin': rolesStaffAdmin, // tableau de bord : accessible à tout le staff (contenu identique, RLS filtre les chiffres visibles)
  '/admin/signalements': rolesStaffAdmin,
  '/admin/support': rolesStaffAdmin,
  '/admin/declarations': rolesStaffAdmin
}

// Retourne la liste des rôles autorisés pour un chemin donné (correspond
// à la clé la plus spécifique qui préfixe le chemin, sinon la valeur par
// défaut).
export const rolesAutorisesPourPage = (chemin) => {
  const cles = Object.keys(permissionsParPage).sort((a, b) => b.length - a.length)
  const cle = cles.find((c) => chemin === c || chemin.startsWith(c + '/'))
  return cle ? permissionsParPage[cle] : rolesParDefaut
}

export const peutAccederPage = (role, chemin) => !!role && rolesAutorisesPourPage(chemin).includes(role)
