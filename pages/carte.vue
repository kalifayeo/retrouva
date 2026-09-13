<script setup>
const supabase = useSupabase()
const stats = ref({ trouves: null, perdus: null })

onMounted(async () => {
  if (!supabase) return
  const { data } = await supabase.rpc('public_stats')
  if (data) { stats.value.trouves = data.trouves; stats.value.perdus = data.perdus }
})
</script>

<template>
  <div class="section py-8 md:py-12">
    <div class="container-app">
      <span class="eyebrow">Nouvelle fonctionnalité</span>
      <div class="section-divider my-3"></div>
      <h1 class="text-2xl md:text-3xl font-bold mb-2">Carte interactive</h1>
      <p class="text-forest-700/70 mb-6 max-w-2xl">
        Visualisez la répartition des objets perdus et trouvés à travers la Côte d'Ivoire.
        Cliquez sur un point pour voir le détail par ville.
      </p>

      <div class="flex items-center gap-5 mb-5 text-sm flex-wrap">
        <span class="flex items-center gap-2"><span class="h-3 w-3 rounded-full bg-[#DC2626]"></span> Perdus</span>
        <span class="flex items-center gap-2"><span class="h-3 w-3 rounded-full bg-forest-700"></span> Trouvés</span>
        <span class="flex items-center gap-2"><span class="h-3 w-3 rounded-full bg-[#2563EB]"></span> Points partenaires</span>
        <span v-if="stats.perdus !== null" class="text-forest-400 ml-auto hidden sm:inline">
          {{ stats.perdus }} déclarations perdues · {{ stats.trouves }} objets trouvés
        </span>
      </div>

      <div class="card p-2 overflow-hidden">
        <ClientOnly>
          <RetrouvaCarte :interactive="true" hauteur="65vh" />
        </ClientOnly>
      </div>

      <p class="text-xs text-forest-400 mt-4 text-center">
        Les positions sont approximatives (centrées sur chaque ville), afin de ne jamais révéler
        de localisation précise ou d'information personnelle.
      </p>
    </div>
  </div>
</template>
