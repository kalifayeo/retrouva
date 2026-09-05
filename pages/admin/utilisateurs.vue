<script setup>
definePageMeta({ middleware: 'admin', layout: 'admin' })

const supabase = useSupabase()
const { profile } = useAuth()
const utilisateurs = ref([])
const partenaires = ref([])
const pointsRelais = ref([])
const loading = ref(true)

const roles = ['utilisateur', 'utilisateur_verifie', 'moderateur', 'administrateur', 'partenaire', 'agent_relais', 'super_administrateur']

// Seul un super_administrateur peut changer le rôle d'un compte (donc
// notamment promouvoir/rétrograder d'autres administrateurs). Un
// administrateur voit la liste des comptes mais le rôle y est affiché en
// lecture seule. Rappel : ceci est un confort d'usage côté Nuxt — la vraie
// barrière est le trigger "proteger_role_profil" (voir
// supabase/migration_23_roles_permissions.sql), qui bloquerait de toute
// façon une tentative de modification faite en contournant l'interface.
const peutGererRoles = computed(() => profile.value?.role === 'super_administrateur')

const charger = async () => {
  loading.value = true
  const [comptes, partners, points] = await Promise.all([
    supabase
      .from('profiles')
      .select('id, nom_affiche, telephone, role, ville, commune, created_at, partner_id, pickup_point_id')
      .order('created_at', { ascending: false }),
    // Un administrateur (comme un super_administrateur) peut rattacher un
    // compte à un partenaire/point relais : ces deux listes servent aux
    // menus déroulants ci-dessous, indépendamment de peutGererRoles.
    supabase.from('partners').select('id, nom').order('nom', { ascending: true }),
    supabase.from('pickup_points').select('id, nom, ville, commune').order('nom', { ascending: true })
  ])
  utilisateurs.value = comptes.data || []
  partenaires.value = partners.data || []
  pointsRelais.value = points.data || []
  loading.value = false
}

// ---------------------------------------------------------------------
// Retour visuel par ligne lors du changement de rôle : jusqu'ici rien ne
// s'affichait pendant/après l'enregistrement (ni succès, ni erreur), ce
// qui donnait l'impression que le clic ne faisait rien.
// ---------------------------------------------------------------------
const enregistrementId = ref(null)
const messageParId = reactive({}) // { [id]: { type: 'succes' | 'erreur', texte } }
const timeoutsParId = {}

const afficherMessage = (id, type, texte) => {
  messageParId[id] = { type, texte }
  if (timeoutsParId[id]) clearTimeout(timeoutsParId[id])
  timeoutsParId[id] = setTimeout(() => { delete messageParId[id] }, 3500)
}

const changerRole = async (u, nouveauRole) => {
  const ancienRole = u.role
  enregistrementId.value = u.id
  const { error } = await supabase.from('profiles').update({ role: nouveauRole }).eq('id', u.id)
  enregistrementId.value = null

  if (error) {
    u.role = ancienRole // on revient à l'ancienne valeur, le select ne doit pas mentir sur l'état réel
    afficherMessage(u.id, 'erreur', "Échec : " + error.message)
  } else {
    u.role = nouveauRole
    afficherMessage(u.id, 'succes', 'Rôle mis à jour ✓')
  }
}

// ---------------------------------------------------------------------
// Rattachement partenaire / point relais — indépendant du rôle
// (supabase/migration_23_roles_permissions.sql ajoute les colonnes
// profiles.partner_id et profiles.pickup_point_id). Un compte "partenaire"
// se rattache à un partenaire ; un compte "agent_relais" se rattache à un
// point relais précis où il travaille. Suivi visuel séparé de celui du
// rôle pour ne pas désactiver le sélecteur de rôle pendant l'opération.
// ---------------------------------------------------------------------
const enregistrementAssignationId = ref(null)
const messageAssignationParId = reactive({})

const afficherMessageAssignation = (id, type, texte) => {
  messageAssignationParId[id] = { type, texte }
  setTimeout(() => { delete messageAssignationParId[id] }, 3500)
}

const assignerPartenaire = async (u, partnerId) => {
  enregistrementAssignationId.value = u.id
  const { error } = await supabase.from('profiles').update({ partner_id: partnerId || null }).eq('id', u.id)
  enregistrementAssignationId.value = null

  if (error) {
    afficherMessageAssignation(u.id, 'erreur', "Échec : " + error.message)
  } else {
    u.partner_id = partnerId || null
    afficherMessageAssignation(u.id, 'succes', 'Rattachement enregistré ✓')
  }
}

const assignerPointRelais = async (u, pickupPointId) => {
  enregistrementAssignationId.value = u.id
  const { error } = await supabase.from('profiles').update({ pickup_point_id: pickupPointId || null }).eq('id', u.id)
  enregistrementAssignationId.value = null

  if (error) {
    afficherMessageAssignation(u.id, 'erreur', "Échec : " + error.message)
  } else {
    u.pickup_point_id = pickupPointId || null
    afficherMessageAssignation(u.id, 'succes', 'Rattachement enregistré ✓')
  }
}

onMounted(charger)
</script>

<template>
  <div class="section py-8 md:py-12">
    <div class="container-app">
      <h1 class="text-2xl font-bold mb-1">Utilisateurs</h1>
      <p class="text-forest-700/70 mb-6">{{ utilisateurs.length }} comptes enregistrés.</p>

      <p v-if="loading" class="text-sm text-forest-500">Chargement…</p>

      <div v-else class="card overflow-x-auto">
        <table class="w-full text-sm">
          <thead class="bg-forest-50 text-forest-700 text-left">
            <tr>
              <th class="px-4 py-3 font-semibold">Nom / Téléphone</th>
              <th class="px-4 py-3 font-semibold">Ville</th>
              <th class="px-4 py-3 font-semibold">Inscrit le</th>
              <th class="px-4 py-3 font-semibold">Rôle</th>
              <th class="px-4 py-3 font-semibold">Rattachement</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-forest-50">
            <tr v-for="u in utilisateurs" :key="u.id">
              <td class="px-4 py-3">
                <p class="font-medium">{{ u.nom_affiche || '—' }}</p>
                <p class="text-xs text-forest-400">{{ u.telephone || '—' }}</p>
              </td>
              <td class="px-4 py-3">{{ u.commune ? `${u.commune}, ` : '' }}{{ u.ville || '—' }}</td>
              <td class="px-4 py-3">{{ new Date(u.created_at).toLocaleDateString('fr-FR') }}</td>
              <td class="px-4 py-3">
                <div v-if="peutGererRoles" class="flex items-center gap-2">
                  <select
                    class="input-field !py-2 !w-auto text-xs"
                    :disabled="enregistrementId === u.id"
                    :class="{ 'opacity-60': enregistrementId === u.id }"
                    :value="u.role"
                    @change="changerRole(u, $event.target.value)"
                  >
                    <option v-for="r in roles" :key="r" :value="r">{{ r }}</option>
                  </select>
                  <IconTab v-if="enregistrementId === u.id" name="clock" class="h-4 w-4 text-forest-400 animate-pulse shrink-0" />
                  <span
                    v-else-if="messageParId[u.id]"
                    class="text-xs font-semibold shrink-0"
                    :class="messageParId[u.id].type === 'succes' ? 'text-forest-600' : 'text-red-500'"
                  >
                    {{ messageParId[u.id].texte }}
                  </span>
                </div>
                <!-- Lecture seule pour un administrateur : la gestion des rôles
                     est réservée au super_administrateur. -->
                <span v-else class="badge bg-forest-50 text-forest-500">{{ u.role }}</span>
              </td>
              <td class="px-4 py-3">
                <!-- Compte partenaire : rattachement à un partenaire du réseau -->
                <div v-if="u.role === 'partenaire'" class="flex items-center gap-2">
                  <select
                    class="input-field !py-2 !w-auto text-xs"
                    :disabled="enregistrementAssignationId === u.id"
                    :class="{ 'opacity-60': enregistrementAssignationId === u.id }"
                    :value="u.partner_id || ''"
                    @change="assignerPartenaire(u, $event.target.value)"
                  >
                    <option value="">— Aucun —</option>
                    <option v-for="p in partenaires" :key="p.id" :value="p.id">{{ p.nom }}</option>
                  </select>
                  <IconTab v-if="enregistrementAssignationId === u.id" name="clock" class="h-4 w-4 text-forest-400 animate-pulse shrink-0" />
                  <span
                    v-else-if="messageAssignationParId[u.id]"
                    class="text-xs font-semibold shrink-0"
                    :class="messageAssignationParId[u.id].type === 'succes' ? 'text-forest-600' : 'text-red-500'"
                  >
                    {{ messageAssignationParId[u.id].texte }}
                  </span>
                </div>

                <!-- Compte agent relais : rattachement à un point relais précis -->
                <div v-else-if="u.role === 'agent_relais'" class="flex items-center gap-2">
                  <select
                    class="input-field !py-2 !w-auto text-xs"
                    :disabled="enregistrementAssignationId === u.id"
                    :class="{ 'opacity-60': enregistrementAssignationId === u.id }"
                    :value="u.pickup_point_id || ''"
                    @change="assignerPointRelais(u, $event.target.value)"
                  >
                    <option value="">— Aucun —</option>
                    <option v-for="p in pointsRelais" :key="p.id" :value="p.id">
                      {{ p.nom }} ({{ p.commune ? p.commune + ', ' : '' }}{{ p.ville }})
                    </option>
                  </select>
                  <IconTab v-if="enregistrementAssignationId === u.id" name="clock" class="h-4 w-4 text-forest-400 animate-pulse shrink-0" />
                  <span
                    v-else-if="messageAssignationParId[u.id]"
                    class="text-xs font-semibold shrink-0"
                    :class="messageAssignationParId[u.id].type === 'succes' ? 'text-forest-600' : 'text-red-500'"
                  >
                    {{ messageAssignationParId[u.id].texte }}
                  </span>
                </div>

                <!-- Tout autre rôle : aucun rattachement pertinent -->
                <span v-else class="text-xs text-forest-300">—</span>
              </td>
            </tr>
          </tbody>
        </table>

        <p v-if="!utilisateurs.length" class="text-center py-10 text-forest-500">
          Aucun utilisateur pour le moment.
        </p>
      </div>
    </div>
  </div>
</template>
