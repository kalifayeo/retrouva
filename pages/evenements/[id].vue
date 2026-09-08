<script setup>
const route = useRoute()
const supabase = useSupabase()

const evenement = ref(null)
const loading = ref(true)
const erreur = ref('')

const charger = async () => {
  loading.value = true
  erreur.value = ''
  if (!supabase) { loading.value = false; return }

  try {
    const { data, error } = await avecDelai(supabase
      .from('events')
      .select('id, titre, description, lieu, date_evenement, image_url, actif')
      .eq('id', route.params.id)
      .maybeSingle())

    if (error) {
      erreur.value = "Une erreur est survenue (" + error.message + ")."
    } else if (!data) {
      erreur.value = "Cet événement n'existe pas ou n'est plus disponible."
    } else {
      evenement.value = data
    }
  } catch (e) {
    erreur.value = e.message || 'Une erreur inattendue est survenue.'
  } finally {
    loading.value = false
  }
}

onMounted(charger)
</script>

<template>
  <div class="section py-10 md:py-16">
    <div class="container-app max-w-2xl">
      <NuxtLink to="/evenements" class="text-sm text-forest-500 flex items-center gap-1 mb-6">
        <IconTab name="arrow" class="h-4 w-4 rotate-180" /> Retour aux événements
      </NuxtLink>

      <p v-if="loading" class="text-sm text-forest-500">Chargement…</p>

      <div v-else-if="erreur" class="text-center py-10">
        <p class="text-sm text-red-600 mb-4">{{ erreur }}</p>
        <button class="btn-outline" @click="charger">Réessayer</button>
      </div>

      <template v-else-if="evenement">
        <div class="card overflow-hidden">
          <img v-if="evenement.image_url" :src="evenement.image_url" :alt="evenement.titre" class="w-full h-56 sm:h-72 object-cover" />
          <div class="p-6 sm:p-8">
            <span class="badge-orange mb-4">
              <IconTab name="clock" class="h-3.5 w-3.5" />
              {{ new Date(evenement.date_evenement).toLocaleDateString('fr-FR', { weekday: 'long', day: 'numeric', month: 'long', year: 'numeric' }) }}
              à {{ new Date(evenement.date_evenement).toLocaleTimeString('fr-FR', { hour: '2-digit', minute: '2-digit' }) }}
            </span>
            <h1 class="text-2xl md:text-3xl font-bold mb-3">{{ evenement.titre }}</h1>
            <p v-if="evenement.lieu" class="text-forest-700/70 flex items-center gap-1.5 mb-6">
              <IconTab name="pin" class="h-4 w-4" /> {{ evenement.lieu }}
            </p>
            <p v-if="evenement.description" class="text-forest-800 leading-relaxed whitespace-pre-line">
              {{ evenement.description }}
            </p>
            <p v-else class="text-forest-400 text-sm">Aucune description supplémentaire pour cet événement.</p>
          </div>
        </div>
      </template>
    </div>
  </div>
</template>
