<script setup>
const supabase = useSupabase()
const evenements = ref([])
const loading = ref(true)

const charger = async () => {
  loading.value = true
  if (!supabase) { loading.value = false; return }
  const { data } = await supabase
    .from('events')
    .select('id, titre, description, lieu, date_evenement, image_url')
    .eq('actif', true)
    .gte('date_evenement', new Date().toISOString())
    .order('date_evenement', { ascending: true })
  evenements.value = data || []
  loading.value = false
}

onMounted(charger)
</script>

<template>
  <div class="section py-10 md:py-16">
    <div class="container-app max-w-3xl">
      <span class="eyebrow">Agenda RETROUVA</span>
      <div class="section-divider my-3"></div>
      <h1 class="text-2xl md:text-3xl font-bold mb-2">Événements</h1>
      <p class="text-forest-700/70 mb-10">
        Journées de restitution, campagnes de sensibilisation et rencontres organisées par
        RETROUVA en Côte d'Ivoire.
      </p>

      <p v-if="loading" class="text-sm text-forest-500">Chargement…</p>

      <div v-else-if="evenements.length" class="space-y-4">
        <NuxtLink v-for="e in evenements" :key="e.id" :to="`/evenements/${e.id}`" class="card-hover overflow-hidden sm:flex">
          <img v-if="e.image_url" :src="e.image_url" :alt="e.titre" class="h-40 sm:h-auto sm:w-48 shrink-0 object-cover" />
          <div class="p-5">
            <span class="badge-orange mb-2">
              <IconTab name="clock" class="h-3.5 w-3.5" />
              {{ new Date(e.date_evenement).toLocaleDateString('fr-FR', { day: 'numeric', month: 'long', year: 'numeric' }) }}
              à {{ new Date(e.date_evenement).toLocaleTimeString('fr-FR', { hour: '2-digit', minute: '2-digit' }) }}
            </span>
            <h2 class="font-display font-semibold text-lg mb-1">{{ e.titre }}</h2>
            <p v-if="e.lieu" class="text-sm text-forest-700/70 flex items-center gap-1.5 mb-2">
              <IconTab name="pin" class="h-3.5 w-3.5" /> {{ e.lieu }}
            </p>
            <p v-if="e.description" class="text-sm text-forest-700/80 line-clamp-2">{{ e.description }}</p>
            <span class="text-savane-600 text-sm font-semibold flex items-center gap-1 mt-2">
              Voir les détails <IconTab name="arrow" class="h-3.5 w-3.5" />
            </span>
          </div>
        </NuxtLink>
      </div>

      <div v-else class="card text-center py-16 text-forest-500">
        Aucun événement prévu pour le moment. Revenez bientôt !
      </div>
    </div>
  </div>
</template>
