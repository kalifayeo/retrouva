<script setup>
const supabase = useSupabase()
const { slidesTerminees } = useIntroSequence()

const config = ref(null)
const pret = ref(false)   // config chargée + condition de position remplie
const fermee = ref(false)

onMounted(async () => {
  if (!supabase || typeof window === 'undefined') return
  // Un seul visionnage par appareil/navigateur, comme l'introduction.
  if (localStorage.getItem('retrouva_intro_video_vue')) return

  const { data } = await supabase
    .from('intro_video_config')
    .select('*')
    .eq('id', 'principal')
    .maybeSingle()

  if (!data || !data.actif || !data.video_url) return
  config.value = data

  if (config.value.position === 'apres') {
    if (slidesTerminees.value) pret.value = true
    else watch(slidesTerminees, (v) => { if (v) pret.value = true })
  } else {
    pret.value = true
  }
})

const visible = computed(() => !!config.value && pret.value && !fermee.value)

// Détecte les liens YouTube / Vimeo pour les intégrer en iframe ; toute
// autre URL (mp4 hébergé, etc.) est lue directement avec <video>.
const idYoutube = computed(() => {
  const url = config.value?.video_url || ''
  const m = url.match(/(?:youtu\.be\/|youtube\.com\/(?:watch\?v=|embed\/|shorts\/))([\w-]{6,})/)
  return m ? m[1] : null
})
const idVimeo = computed(() => {
  const url = config.value?.video_url || ''
  const m = url.match(/vimeo\.com\/(?:video\/)?(\d+)/)
  return m ? m[1] : null
})
const urlIncorporation = computed(() => {
  if (idYoutube.value) return `https://www.youtube.com/embed/${idYoutube.value}?autoplay=1&mute=1&rel=0`
  if (idVimeo.value) return `https://player.vimeo.com/video/${idVimeo.value}?autoplay=1&muted=1`
  return null
})

const fermer = () => {
  fermee.value = true
  localStorage.setItem('retrouva_intro_video_vue', '1')
}
</script>

<template>
  <div
    v-if="visible"
    class="fixed inset-0 z-[65] flex items-center justify-center bg-forest-900/80 backdrop-blur-sm p-4"
  >
    <div class="relative w-full max-w-2xl">
      <div class="flex items-center justify-between mb-3 px-1">
        <p class="text-sm font-display font-semibold text-white truncate pr-3">{{ config?.titre }}</p>
        <button
          class="shrink-0 flex items-center gap-1.5 rounded-full bg-white/10 hover:bg-white/20 text-white text-xs font-semibold px-3.5 py-2 transition-colors tap-target"
          @click="fermer"
        >
          Passer <IconTab name="close" class="h-3.5 w-3.5" />
        </button>
      </div>

      <div class="relative rounded-2xl overflow-hidden shadow-floating bg-black aspect-video">
        <iframe
          v-if="urlIncorporation"
          :src="urlIncorporation"
          class="absolute inset-0 h-full w-full"
          frameborder="0"
          allow="autoplay; encrypted-media; picture-in-picture"
          allowfullscreen
        ></iframe>
        <video
          v-else
          :src="config?.video_url"
          class="absolute inset-0 h-full w-full object-contain bg-black"
          controls
          autoplay
          muted
          playsinline
          @ended="fermer"
        ></video>
      </div>
    </div>
  </div>
</template>
