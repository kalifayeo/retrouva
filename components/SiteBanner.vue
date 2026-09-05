<script setup>
const props = defineProps({
  position: { type: String, default: 'accueil' }
})

const supabase = useSupabase()
const banniere = ref(null)
const fermee = ref(false)

const cleFermeture = computed(() => banniere.value ? `retrouva_banniere_fermee_${banniere.value.id}` : null)

onMounted(async () => {
  if (!supabase) return
  const today = new Date().toISOString().slice(0, 10)
  const { data } = await supabase
    .from('banners')
    .select('*')
    .eq('actif', true)
    .in('position', [props.position, 'toutes_pages'])
    .order('created_at', { ascending: false })
    .limit(5)

  banniere.value = (data || []).find(b =>
    (!b.date_debut || b.date_debut <= today) && (!b.date_fin || b.date_fin >= today)
  ) || null

  // Une fois fermée par l'utilisateur (bouton croix), une bannière ne
  // réapparaît pas pendant le reste de la session — pratique pour les
  // publicités ou annonces externes qu'on ne veut pas imposer en boucle.
  if (banniere.value && sessionStorage.getItem(cleFermeture.value)) {
    fermee.value = true
  }
})

const fermer = () => {
  fermee.value = true
  if (cleFermeture.value) sessionStorage.setItem(cleFermeture.value, '1')
}
</script>

<template>
  <div v-if="banniere && !fermee" class="relative shadow-floating mb-10 overflow-hidden">
    <a
      :href="banniere.lien_url || '#'"
      :target="banniere.lien_url ? '_blank' : undefined"
      rel="noopener sponsored"
      class="group relative block bg-brand-gradient"
    >
      <div class="pointer-events-none absolute -top-10 -right-10 h-40 w-40 rounded-full bg-white/10 blur-2xl"></div>

      <div class="relative flex items-center gap-5 p-5 sm:p-6 pr-14 sm:pr-6">
        <img
          v-if="banniere.image_url"
          :src="banniere.image_url"
          class="h-16 w-16 sm:h-24 sm:w-24 object-cover shrink-0 ring-2 ring-white/40"
        />
        <div class="min-w-0 flex-1">
          <span class="inline-flex items-center gap-1.5 rounded-full bg-white/20 backdrop-blur px-3 py-1 text-[11px] font-bold uppercase tracking-wide text-white mb-2">
            <IconTab name="megaphone" class="h-3 w-3" /> Publicité<span v-if="banniere.nom_entreprise"> · {{ banniere.nom_entreprise }}</span>
          </span>
          <h3 class="font-display font-bold text-white text-lg sm:text-xl mb-0.5">{{ banniere.titre }}</h3>
          <p class="text-sm text-white/85 line-clamp-2">{{ banniere.texte }}</p>
        </div>
        <span
          v-if="banniere.lien_url"
          class="hidden sm:flex shrink-0 items-center gap-1.5 rounded-full bg-white text-[#0B3D24] px-4 py-2.5 text-sm font-semibold group-hover:bg-ivoire-100 transition-colors"
        >
          En savoir plus <IconTab name="arrow" class="h-4 w-4" />
        </span>
      </div>
    </a>

    <button
      class="absolute top-3 right-3 sm:top-4 sm:right-4 flex h-8 w-8 items-center justify-center rounded-full bg-white/25 hover:bg-white/40 text-white backdrop-blur transition-colors"
      aria-label="Fermer la publicité"
      @click="fermer"
    >
      <IconTab name="close" class="h-4 w-4" />
    </button>
  </div>
</template>
