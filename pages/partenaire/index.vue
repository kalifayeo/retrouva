<script setup>
// Jusqu'ici cette page affichait 3 chiffres codés en dur ("42/35/38"),
// sans lien avec la base. On la rend réelle : chaque compte "partenaire"
// est désormais rattaché en base à un partenaire précis (profiles.partner_id,
// voir supabase/migration_23_roles_permissions.sql) et on affiche les
// statistiques de SES points relais uniquement (RLS dédiée, même migration).
definePageMeta({ middleware: 'partenaire' })

const supabase = useSupabase()
const { profile } = useAuth()

const chargement = ref(true)
const erreur = ref('')
const nomPartenaire = ref('')
const pointsRelais = ref([])
const demandes = ref([])

const stats = computed(() => {
  const idsPoints = pointsRelais.value.map((p) => p.id)
  const demandesAuxPoints = demandes.value.filter((d) => idsPoints.includes(d.pickup_point_id))
  const remisesFinalisees = demandesAuxPoints.filter((d) => {
    const r = d.restitutions?.[0]
    return r && r.confirmee_par_proprietaire && r.confirmee_par_trouveur
  })

  return [
    { label: 'Objets déposés à vos points relais', value: demandesAuxPoints.length },
    { label: 'Remises finalisées', value: remisesFinalisees.length },
    { label: 'Points relais actifs', value: pointsRelais.value.filter((p) => p.actif).length }
  ]
})

const charger = async () => {
  chargement.value = true
  erreur.value = ''

  // Un administrateur/super_administrateur peut ouvrir cette page pour
  // dépanner, mais n'a par définition aucun partner_id : on le lui indique
  // simplement plutôt que d'afficher des statistiques vides sans explication.
  if (!profile.value?.partner_id) {
    if (profile.value && ['administrateur', 'super_administrateur'].includes(profile.value.role)) {
      erreur.value = "Ce compte n'est rattaché à aucun partenaire (normal pour un compte admin) : rien à afficher ici."
    } else {
      erreur.value = "Votre compte n'est pas encore rattaché à un partenaire. Contactez l'équipe RETROUVA."
    }
    chargement.value = false
    return
  }

  const { data: partenaire } = await supabase
    .from('partners')
    .select('nom')
    .eq('id', profile.value.partner_id)
    .maybeSingle()
  nomPartenaire.value = partenaire?.nom || ''

  const { data: points } = await supabase
    .from('pickup_points')
    .select('id, nom, ville, commune, actif')
    .eq('partner_id', profile.value.partner_id)
  pointsRelais.value = points || []

  const idsPoints = pointsRelais.value.map((p) => p.id)
  if (idsPoints.length) {
    const { data } = await supabase
      .from('restitution_requests')
      .select('id, pickup_point_id, statut, created_at, restitutions(confirmee_par_proprietaire, confirmee_par_trouveur)')
      .in('pickup_point_id', idsPoints)
      .order('created_at', { ascending: false })
    demandes.value = data || []
  }

  chargement.value = false
}

onMounted(charger)
</script>

<template>
  <div class="section py-8 md:py-12">
    <div class="container-app">
      <h1 class="text-2xl font-bold mb-1">Espace partenaire</h1>
      <p class="text-forest-700/70 mb-8">
        <template v-if="nomPartenaire">Suivi de l'activité de vos points relais — {{ nomPartenaire }}.</template>
        <template v-else>Suivi de l'activité de votre point relais.</template>
      </p>

      <p v-if="chargement" class="text-sm text-forest-500">Chargement…</p>

      <template v-else-if="erreur">
        <div class="card p-6 text-center text-forest-500">{{ erreur }}</div>
      </template>

      <template v-else>
        <div class="grid sm:grid-cols-3 gap-4 mb-10">
          <div v-for="s in stats" :key="s.label" class="card p-6 text-center">
            <div class="text-3xl font-display font-extrabold text-savane-500 mb-1">{{ s.value }}</div>
            <div class="text-sm text-forest-700/70">{{ s.label }}</div>
          </div>
        </div>

        <h2 class="font-display font-bold text-lg mb-3">Vos points relais</h2>
        <div v-if="pointsRelais.length" class="space-y-3">
          <div v-for="p in pointsRelais" :key="p.id" class="card p-4 flex items-center justify-between gap-3">
            <div class="min-w-0">
              <p class="font-medium text-sm truncate">{{ p.nom }}</p>
              <p class="text-xs text-forest-400">{{ p.commune ? `${p.commune}, ` : '' }}{{ p.ville }}</p>
            </div>
            <span class="badge" :class="p.actif ? 'badge-green' : 'bg-forest-50 text-forest-400'">{{ p.actif ? 'actif' : 'inactif' }}</span>
          </div>
        </div>
        <p v-else class="card text-center py-10 text-forest-500">Aucun point relais rattaché à votre compte pour le moment.</p>
      </template>
    </div>
  </div>
</template>
