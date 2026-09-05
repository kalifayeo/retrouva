<script setup>
definePageMeta({ middleware: 'auth' })

const { objectTypes } = useObjectTypes()
const { user } = useAuth()
const supabase = useSupabase()

const resultats = ref([])
const loading = ref(true)

const typeInfo = (id) => objectTypes.find(t => t.id === id) || { label: id, image: '' }

const charger = async () => {
  loading.value = true
  if (!supabase || !user.value) { loading.value = false; return }

  try {
    const { data, error } = await avecDelai(supabase
      .from('matches')
      .select(`
        id, score, details, created_at,
        lost_report:lost_reports!inner(id, user_id, object_type_id),
        found_report:found_reports(id, ville, commune, date_trouvaille, object_type_id)
      `)
      .eq('lost_report.user_id', user.value.id)
      .eq('masque', false)
      .order('score', { ascending: false }))

    if (error) {
      console.error('Erreur chargement résultats :', error)
    } else {
      // Un même objet trouvé peut correspondre à plusieurs de vos déclarations
      // (ex. si vous avez déclaré la perte deux fois par erreur) : on ne garde
      // que la meilleure correspondance par objet trouvé pour éviter les
      // doublons visuels.
      const parObjetTrouve = new Map()
      for (const m of data || []) {
        const cle = m.found_report.id
        if (!parObjetTrouve.has(cle) || parObjetTrouve.get(cle).score < m.score) {
          parObjetTrouve.set(cle, m)
        }
      }
      resultats.value = Array.from(parObjetTrouve.values()).sort((a, b) => b.score - a.score)
    }
  } catch (e) {
    console.error('Erreur inattendue :', e)
  } finally {
    loading.value = false
  }
}

const scoreColor = (score) => {
  if (score >= 80) return 'text-forest-600 bg-forest-50'
  if (score >= 60) return 'text-savane-700 bg-savane-50'
  return 'text-forest-400 bg-ivoire-200'
}

onMounted(charger)
</script>

<template>
  <div class="section py-8 md:py-12">
    <div class="container-app">
      <span class="eyebrow">Vos déclarations de perte</span>
      <div class="section-divider my-3"></div>
      <div class="flex flex-wrap items-end justify-between gap-3 mb-8">
        <div>
          <h1 class="text-2xl md:text-3xl font-bold mb-1">Mes correspondances</h1>
          <p class="text-forest-700/70">
            Calculées automatiquement à partir de vos déclarations de perte.
          </p>
        </div>
        <span v-if="resultats.length" class="badge-green">{{ resultats.length }} correspondance{{ resultats.length > 1 ? 's' : '' }}</span>
      </div>

      <p v-if="loading" class="text-sm text-forest-500">Chargement…</p>

      <div v-else-if="resultats.length" class="grid gap-4 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4">
        <NuxtLink v-for="r in resultats" :key="r.id" :to="`/resultats/${r.id}`" class="card-hover overflow-hidden">
          <div class="relative h-32 bg-ivoire-100">
            <img
              v-if="typeInfo(r.found_report.object_type_id).image"
              :src="typeInfo(r.found_report.object_type_id).image"
              :alt="typeInfo(r.found_report.object_type_id).label"
              class="h-full w-full object-cover"
            />
            <span v-else class="flex h-full items-center justify-center text-forest-300">
              <IconTab name="card" class="h-8 w-8" />
            </span>
            <span class="badge absolute top-3 right-3" :class="scoreColor(r.score)">{{ r.score }}%</span>
          </div>
          <div class="p-4">
            <h3 class="font-display font-semibold mb-1">{{ typeInfo(r.found_report.object_type_id).label }}</h3>
            <p class="text-sm text-forest-700/70 flex items-center gap-1.5 mb-1">
              <IconTab name="pin" class="h-3.5 w-3.5" />
              {{ r.found_report.commune ? `${r.found_report.commune}, ` : '' }}{{ r.found_report.ville }}
            </p>
            <p class="text-xs text-forest-400">
              Trouvé le {{ new Date(r.found_report.date_trouvaille).toLocaleDateString('fr-FR') }}
            </p>
          </div>
        </NuxtLink>
      </div>

      <div v-else class="card text-center py-16 px-6 text-forest-500">
        <span class="mx-auto flex h-14 w-14 items-center justify-center rounded-full bg-forest-50 text-forest-400 mb-4">
          <IconTab name="search" class="h-6 w-6" />
        </span>
        Aucune correspondance pour le moment. Dès qu'un objet compatible avec l'une de vos
        déclarations de perte est trouvé, il apparaîtra ici automatiquement.
        <NuxtLink to="/perdu" class="text-savane-600 font-semibold block mt-3">Déclarer un objet perdu</NuxtLink>
      </div>
    </div>
  </div>
</template>
