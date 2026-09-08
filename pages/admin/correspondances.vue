<script setup>
definePageMeta({ middleware: 'admin', layout: 'admin' })

const supabase = useSupabase()
const { objectTypes } = useObjectTypes()

const matches = ref([])
const loading = ref(true)

const labelType = (id) => objectTypes.find(t => t.id === id)?.label || id

const charger = async () => {
  loading.value = true
  const { data } = await supabase
    .from('matches')
    .select(`
      id, score, masque, created_at,
      lost_report:lost_reports(object_type_id, ville, commune),
      found_report:found_reports(object_type_id, ville, commune)
    `)
    .order('created_at', { ascending: false })
    .limit(100)
  matches.value = data || []
  loading.value = false
}

const basculerMasque = async (m) => {
  const nouveauMasque = !m.masque
  await supabase.from('matches').update({ masque: nouveauMasque }).eq('id', m.id)
  m.masque = nouveauMasque
}

const supprimer = async (id) => {
  if (!confirm('Supprimer définitivement cette correspondance ?')) return
  await supabase.from('matches').delete().eq('id', id)
  matches.value = matches.value.filter(m => m.id !== id)
}

onMounted(charger)
</script>

<template>
  <div class="section py-8 md:py-12">
    <div class="container-app">
      <h1 class="text-2xl font-bold mb-1">Correspondances</h1>
      <p class="text-forest-700/70 mb-6">{{ matches.length }} correspondances calculées automatiquement.</p>

      <p v-if="loading" class="text-sm text-forest-500">Chargement…</p>

      <div v-else class="card overflow-x-auto">
        <table class="w-full text-sm">
          <thead class="bg-forest-50 text-forest-700 text-left">
            <tr>
              <th class="px-4 py-3 font-semibold">Objet perdu</th>
              <th class="px-4 py-3 font-semibold">Objet trouvé</th>
              <th class="px-4 py-3 font-semibold">Score</th>
              <th class="px-4 py-3 font-semibold">Statut</th>
              <th class="px-4 py-3 font-semibold"></th>
            </tr>
          </thead>
          <tbody class="divide-y divide-forest-50">
            <tr v-for="m in matches" :key="m.id">
              <td class="px-4 py-3">
                {{ labelType(m.lost_report?.object_type_id) }}
                <span class="text-forest-400 text-xs block">{{ m.lost_report?.commune ? `${m.lost_report.commune}, ` : '' }}{{ m.lost_report?.ville }}</span>
              </td>
              <td class="px-4 py-3">
                {{ labelType(m.found_report?.object_type_id) }}
                <span class="text-forest-400 text-xs block">{{ m.found_report?.commune ? `${m.found_report.commune}, ` : '' }}{{ m.found_report?.ville }}</span>
              </td>
              <td class="px-4 py-3 font-semibold">{{ m.score }}%</td>
              <td class="px-4 py-3">
                <span class="badge" :class="m.masque ? 'bg-ivoire-200 text-forest-400' : 'badge-green'">
                  {{ m.masque ? 'masquée' : 'visible' }}
                </span>
              </td>
              <td class="px-4 py-3 text-right whitespace-nowrap">
                <button class="text-xs text-forest-600 font-semibold hover:underline mr-3" @click="basculerMasque(m)">
                  {{ m.masque ? 'Afficher' : 'Masquer' }}
                </button>
                <button class="text-xs text-red-500 font-semibold hover:underline" @click="supprimer(m.id)">
                  Supprimer
                </button>
              </td>
            </tr>
          </tbody>
        </table>

        <p v-if="!matches.length" class="text-center py-10 text-forest-500">
          Aucune correspondance pour le moment.
        </p>
      </div>
    </div>
  </div>
</template>
