<script setup>
definePageMeta({ middleware: 'admin', layout: 'admin' })

const supabase = useSupabase()
const signalements = ref([])
const loading = ref(true)

const statutStyle = {
  ouvert: 'badge-orange',
  en_cours: 'badge-green',
  clos: 'badge bg-forest-50 text-forest-400'
}

const charger = async () => {
  loading.value = true
  const { data } = await supabase
    .from('reports')
    .select('id, cible_type, cible_id, motif, details, statut, created_at')
    .order('created_at', { ascending: false })
  signalements.value = data || []
  loading.value = false
}

const changerStatut = async (s, statut) => {
  await supabase.from('reports').update({ statut }).eq('id', s.id)
  s.statut = statut
}

onMounted(charger)
</script>

<template>
  <div class="section py-8 md:py-12">
    <div class="container-app max-w-3xl">
      <h1 class="text-2xl font-bold mb-1">Signalements</h1>
      <p class="text-forest-700/70 mb-6">Modération et lutte contre la fraude.</p>

      <p v-if="loading" class="text-sm text-forest-500">Chargement…</p>

      <div v-else-if="signalements.length" class="space-y-3">
        <div v-for="s in signalements" :key="s.id" class="card p-5">
          <div class="flex items-start justify-between gap-3 mb-2">
            <div>
              <p class="font-display font-semibold text-sm">{{ s.motif }}</p>
              <p class="text-xs text-forest-400 mt-0.5">
                {{ s.cible_type }} · {{ new Date(s.created_at).toLocaleDateString('fr-FR') }}
              </p>
            </div>
            <span :class="statutStyle[s.statut] || 'badge'">{{ s.statut }}</span>
          </div>
          <p v-if="s.details" class="text-sm text-forest-700 mb-3">{{ s.details }}</p>
          <div class="flex gap-2">
            <button v-if="s.statut !== 'en_cours'" class="text-xs font-semibold text-savane-600 hover:underline" @click="changerStatut(s, 'en_cours')">
              Marquer en cours
            </button>
            <button v-if="s.statut !== 'clos'" class="text-xs font-semibold text-forest-600 hover:underline" @click="changerStatut(s, 'clos')">
              Clore
            </button>
          </div>
        </div>
      </div>

      <div v-else class="card text-center py-16 text-forest-500">
        Aucun signalement pour le moment.
      </div>
    </div>
  </div>
</template>
