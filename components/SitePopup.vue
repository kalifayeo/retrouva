<script setup>
const supabase = useSupabase()
const popup = ref(null)
const visible = ref(false)

onMounted(async () => {
  if (!supabase) return
  // Un seul affichage par visite (session), pour ne pas gêner la navigation.
  if (sessionStorage.getItem('retrouva_popup_vu')) return

  const today = new Date().toISOString().slice(0, 10)
  const { data } = await supabase
    .from('popups')
    .select('*')
    .eq('actif', true)
    .order('created_at', { ascending: false })
    .limit(5)

  const trouve = (data || []).find(p =>
    (!p.date_debut || p.date_debut <= today) && (!p.date_fin || p.date_fin >= today)
  )

  if (trouve) {
    popup.value = trouve
    visible.value = true
  }
})

const fermer = () => {
  visible.value = false
  sessionStorage.setItem('retrouva_popup_vu', '1')
}
</script>

<template>
  <div
    v-if="visible && popup"
    class="fixed inset-0 z-50 flex items-center justify-center bg-forest-900/60 backdrop-blur-sm p-4"
    @click.self="fermer"
  >
    <div class="relative w-full max-w-lg bg-white rounded-[1.75rem] shadow-floating overflow-hidden">
      <!-- Bandeau supérieur : badge "Publicité" + Fermer, comme un vrai encart sponsorisé -->
      <div class="flex items-center justify-between px-6 pt-5">
        <span class="inline-flex items-center gap-1.5 rounded-full bg-forest-50 px-3 py-1 text-[11px] font-bold uppercase tracking-wide text-forest-500">
          <IconTab name="megaphone" class="h-3 w-3" /> Publicité<span v-if="popup.nom_entreprise"> · {{ popup.nom_entreprise }}</span>
        </span>
        <button class="text-sm font-semibold text-forest-400 hover:text-forest-700 transition-colors" @click="fermer">
          Fermer
        </button>
      </div>

      <div class="flex items-start gap-5 p-6 pt-5">
        <span
          class="flex h-16 w-16 sm:h-20 sm:w-20 shrink-0 items-center justify-center rounded-2xl overflow-hidden bg-forest-800"
        >
          <img v-if="popup.image_url" :src="popup.image_url" class="h-full w-full object-cover" alt="" />
          <IconTab v-else name="card" class="h-8 w-8 text-white" />
        </span>
        <div class="min-w-0">
          <h3 class="font-display font-bold text-lg sm:text-xl leading-snug mb-1.5">{{ popup.titre }}</h3>
          <p class="text-forest-700/75 text-sm leading-relaxed">{{ popup.texte }}</p>
        </div>
      </div>

      <div class="flex items-center justify-between gap-4 px-6 pb-6 pt-1">
        <span class="text-xs text-forest-300 font-semibold tracking-wide uppercase truncate">RETROUVA</span>
        <a
          v-if="popup.lien_url"
          :href="popup.lien_url"
          target="_blank"
          rel="noopener sponsored"
          class="btn-accent !px-6 !py-2.5 text-sm shrink-0"
        >
          {{ popup.lien_label || 'Ouvrir' }} <IconTab name="arrow" class="h-3.5 w-3.5" />
        </a>
        <button v-else class="btn-outline !px-6 !py-2.5 text-sm shrink-0" @click="fermer">
          Fermer
        </button>
      </div>
    </div>
  </div>
</template>
