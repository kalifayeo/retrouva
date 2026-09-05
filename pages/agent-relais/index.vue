<script setup>
// Nouvelle page (n'existait pas avant) : permet à un compte "agent_relais"
// de confirmer la réception ou la remise physique d'un objet à SON point
// relais. Rattachement en base via profiles.pickup_point_id, RLS dédiée
// dans supabase/migration_23_roles_permissions.sql.
//
// Important : cette confirmation est un enregistrement de traçabilité
// complémentaire (colonnes confirmee_par_agent / agent_id /
// date_confirmation_agent sur "restitutions"). Elle ne remplace ni ne
// bloque le circuit existant où le propriétaire et le trouveur confirment
// eux-mêmes la restitution dans leur messagerie (voir pages/messagerie) :
// les deux mécanismes coexistent, sans rien changer à celui déjà en place.
definePageMeta({ middleware: 'agent-relais' })

const supabase = useSupabase()
const { profile } = useAuth()
const { objectTypes } = useObjectTypes()

const chargement = ref(true)
const erreur = ref('')
const nomPointRelais = ref('')
const demandes = ref([])
const actionEnCoursId = ref(null)

const labelType = (id) => objectTypes.find((t) => t.id === id)?.label || id

const charger = async () => {
  chargement.value = true
  erreur.value = ''

  if (!profile.value?.pickup_point_id) {
    if (profile.value && ['administrateur', 'super_administrateur'].includes(profile.value.role)) {
      erreur.value = "Ce compte n'est rattaché à aucun point relais (normal pour un compte admin) : rien à afficher ici."
    } else {
      erreur.value = "Votre compte n'est pas encore rattaché à un point relais. Contactez l'équipe RETROUVA."
    }
    chargement.value = false
    return
  }

  const { data: point } = await supabase
    .from('pickup_points')
    .select('nom, ville, commune')
    .eq('id', profile.value.pickup_point_id)
    .maybeSingle()
  nomPointRelais.value = point?.nom || ''

  const { data, error } = await supabase
    .from('restitution_requests')
    .select(`
      id, statut, created_at,
      match:matches(
        lost_report:lost_reports(object_type_id),
        found_report:found_reports(object_type_id)
      ),
      restitutions(id, confirmee_par_proprietaire, confirmee_par_trouveur, confirmee_par_agent, date_confirmation_agent)
    `)
    .eq('pickup_point_id', profile.value.pickup_point_id)
    .order('created_at', { ascending: false })

  if (error) {
    erreur.value = 'Erreur de chargement : ' + error.message
  } else {
    demandes.value = data || []
  }
  chargement.value = false
}

const restitutionDe = (d) => d.restitutions?.[0] || null

const confirmerAuPoint = async (d) => {
  actionEnCoursId.value = d.id
  const existante = restitutionDe(d)
  const payload = {
    confirmee_par_agent: true,
    agent_id: profile.value.id,
    date_confirmation_agent: new Date().toISOString()
  }

  const res = existante
    ? await supabase.from('restitutions').update(payload).eq('id', existante.id)
    : await supabase.from('restitutions').insert({ restitution_request_id: d.id, ...payload })

  if (!res.error) await charger()
  actionEnCoursId.value = null
}

onMounted(charger)
</script>

<template>
  <div class="section py-8 md:py-12">
    <div class="container-app max-w-3xl">
      <h1 class="text-2xl font-bold mb-1">Espace agent relais</h1>
      <p class="text-forest-700/70 mb-8">
        <template v-if="nomPointRelais">Remises suivies à votre point relais — {{ nomPointRelais }}.</template>
        <template v-else>Remises suivies à votre point relais.</template>
      </p>

      <p v-if="chargement" class="text-sm text-forest-500">Chargement…</p>

      <div v-else-if="erreur" class="card p-6 text-center text-forest-500">{{ erreur }}</div>

      <div v-else-if="demandes.length" class="space-y-3">
        <div v-for="d in demandes" :key="d.id" class="card p-4">
          <div class="flex items-start justify-between gap-3 mb-2">
            <div class="min-w-0">
              <p class="font-display font-semibold text-sm">
                {{ labelType(d.match?.found_report?.object_type_id || d.match?.lost_report?.object_type_id) }}
              </p>
              <p class="text-xs text-forest-400">
                Demande de remise du {{ new Date(d.created_at).toLocaleDateString('fr-FR') }}
              </p>
            </div>
            <span
              class="badge"
              :class="restitutionDe(d)?.confirmee_par_agent ? 'badge-green' : 'badge-orange'"
            >
              {{ restitutionDe(d)?.confirmee_par_agent ? 'Confirmé au point relais' : 'En attente' }}
            </span>
          </div>

          <div class="flex flex-wrap items-center gap-3 text-xs text-forest-500 mb-3">
            <span :class="restitutionDe(d)?.confirmee_par_proprietaire ? 'text-forest-600 font-semibold' : ''">
              Propriétaire {{ restitutionDe(d)?.confirmee_par_proprietaire ? '✓ confirmé' : 'en attente' }}
            </span>
            <span :class="restitutionDe(d)?.confirmee_par_trouveur ? 'text-forest-600 font-semibold' : ''">
              Trouveur {{ restitutionDe(d)?.confirmee_par_trouveur ? '✓ confirmé' : 'en attente' }}
            </span>
          </div>

          <button
            v-if="!restitutionDe(d)?.confirmee_par_agent"
            class="btn-primary text-sm !py-2"
            :disabled="actionEnCoursId === d.id"
            :class="{ 'opacity-60': actionEnCoursId === d.id }"
            @click="confirmerAuPoint(d)"
          >
            {{ actionEnCoursId === d.id ? 'Enregistrement…' : "Confirmer réception/remise à mon point" }}
          </button>
          <p v-else class="text-xs text-forest-400">
            Confirmé le {{ new Date(restitutionDe(d).date_confirmation_agent).toLocaleDateString('fr-FR') }}
          </p>
        </div>
      </div>

      <div v-else class="card text-center py-16 px-6 text-forest-500">
        Aucune remise en attente à votre point relais pour le moment.
      </div>
    </div>
  </div>
</template>
