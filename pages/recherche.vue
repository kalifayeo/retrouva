<script setup>
definePageMeta({ middleware: 'auth' })

const route = useRoute()
const { objectTypes } = useObjectTypes()
const supabase = useSupabase()

const q = ref(route.query.q || '')
const resultats = ref([])
const loading = ref(false)
const dejaCherche = ref(false)

const typeInfo = (id) => objectTypes.find(t => t.id === id) || { label: id, image: '' }

const rechercher = async () => {
  if (!q.value.trim() || !supabase) return
  loading.value = true
  dejaCherche.value = true

  const terme = q.value.trim()
  const typeCorrespondant = objectTypes.find(t =>
    t.label.toLowerCase().includes(terme.toLowerCase()) || terme.toLowerCase().includes(t.label.toLowerCase())
  )

  try {
    let requete = supabase
      .from('found_reports')
      .select('id, object_type_id, ville, commune, date_trouvaille, created_at')
      .eq('statut', 'active')
      .order('created_at', { ascending: false })
      .limit(30)

    if (typeCorrespondant) {
      requete = requete.eq('object_type_id', typeCorrespondant.id)
    } else {
      requete = requete.or(`ville.ilike.%${terme}%,commune.ilike.%${terme}%`)
    }

    const { data, error } = await avecDelai(requete)
    if (!error) resultats.value = data || []
  } finally {
    loading.value = false
  }
}

onMounted(() => { if (q.value) rechercher() })
</script>

<template>
  <div class="section py-8 md:py-12">
    <div class="container-app max-w-4xl">
      <span class="eyebrow">Recherche publique</span>
      <div class="section-divider my-3"></div>
      <h1 class="text-2xl md:text-3xl font-bold mb-2">Rechercher un objet trouvé</h1>
      <p class="text-forest-700/70 mb-6">
        Cherchez par type d'objet (ex. "carte d'identité") ou par ville/commune, parmi toutes les
        déclarations publiées.
      </p>

      <form class="flex flex-col sm:flex-row gap-3 mb-8" @submit.prevent="rechercher">
        <div class="flex-1 flex items-center gap-3 rounded-2xl bg-white border border-forest-100 px-4 py-3">
          <IconTab name="search" class="h-5 w-5 text-forest-400 shrink-0" />
          <input v-model="q" type="text" placeholder="Ex. carte d'identité, Yopougon…" class="w-full text-sm outline-none placeholder:text-forest-300" />
        </div>
        <button type="submit" class="btn-primary shrink-0">Rechercher</button>
      </form>

      <p v-if="loading" class="text-sm text-forest-500">Recherche…</p>

      <div v-else-if="resultats.length" class="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
        <div v-for="r in resultats" :key="r.id" class="card overflow-hidden">
          <div class="relative h-28 bg-ivoire-100">
            <img v-if="typeInfo(r.object_type_id).image" :src="typeInfo(r.object_type_id).image" class="h-full w-full object-cover" />
            <span v-else class="flex h-full items-center justify-center text-forest-300">
              <IconTab name="card" class="h-7 w-7" />
            </span>
          </div>
          <div class="p-4">
            <h3 class="font-display font-semibold text-sm mb-1">{{ typeInfo(r.object_type_id).label }}</h3>
            <p class="text-xs text-forest-500 flex items-center gap-1.5">
              <IconTab name="pin" class="h-3 w-3" /> {{ r.commune ? `${r.commune}, ` : '' }}{{ r.ville }}
            </p>
            <p class="text-xs text-forest-400 mt-1">Trouvé le {{ new Date(r.date_trouvaille).toLocaleDateString('fr-FR') }}</p>
          </div>
        </div>
      </div>

      <div v-else-if="dejaCherche" class="card text-center py-16 text-forest-500">
        Aucun résultat pour « {{ q }} ». Essayez un autre type d'objet ou une autre ville.
        <NuxtLink to="/perdu" class="text-savane-600 font-semibold block mt-2">Déclarer cette perte</NuxtLink>
      </div>

      <div v-else class="card text-center py-16 text-forest-400">
        Entrez un type d'objet ou une ville pour lancer votre recherche.
      </div>
    </div>
  </div>
</template>
