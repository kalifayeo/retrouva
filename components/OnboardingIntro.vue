<script setup>
const supabase = useSupabase()
const { slidesTerminees } = useIntroSequence()
const slides = ref([])
const step = ref(0)
const visible = ref(false)

const total = computed(() => slides.value.length)
const actuel = computed(() => slides.value[step.value] || null)
const progression = computed(() => total.value ? ((step.value + 1) / total.value) * 100 : 0)
const dernierePage = computed(() => step.value === total.value - 1)

onMounted(async () => {
  if (!supabase || typeof window === 'undefined') return
  // Affichée une seule fois par appareil/navigateur (jusqu'à ce qu'elle soit
  // vue en entier ou passée) — pas à chaque visite, pour ne pas gêner.
  if (localStorage.getItem('retrouva_intro_vue')) { slidesTerminees.value = true; return }

  const { data } = await supabase
    .from('onboarding_slides')
    .select('id, titre, description, icone')
    .eq('actif', true)
    .order('ordre', { ascending: true })

  slides.value = data || []
  if (slides.value.length) visible.value = true
  else slidesTerminees.value = true // rien à montrer : ne bloque pas une éventuelle vidéo "après l'introduction"
})

const suivant = () => {
  if (!dernierePage.value) step.value++
  else terminer()
}
const precedent = () => { if (step.value > 0) step.value-- }
const passer = () => terminer()
const terminer = () => {
  visible.value = false
  localStorage.setItem('retrouva_intro_vue', '1')
  slidesTerminees.value = true
}
</script>

<template>
  <div v-if="visible && actuel" class="fixed inset-0 z-[60] flex items-center justify-center bg-forest-900/60 backdrop-blur-sm p-4">
    <div class="relative w-full max-w-md bg-white rounded-3xl overflow-hidden shadow-floating max-h-[90vh] overflow-y-auto">
      <!-- Barre de progression : centrée, bien visible, en haut de la carte -->
      <div class="h-2 bg-forest-50">
        <div class="h-full bg-savane-500 transition-all duration-300 ease-out" :style="{ width: progression + '%' }"></div>
      </div>

      <button
        class="absolute top-5 right-4 z-10 flex h-8 w-8 items-center justify-center rounded-full bg-forest-50 text-forest-600 hover:bg-forest-100"
        @click="terminer"
        aria-label="Fermer l'introduction"
      >
        <IconTab name="close" class="h-4 w-4" />
      </button>

      <div class="p-7 sm:p-9 text-center">
        <p class="text-xs font-bold tracking-wide text-forest-400 mb-6">{{ step + 1 }} / {{ total }}</p>

        <span class="mx-auto flex h-16 w-16 items-center justify-center rounded-2xl bg-savane-500 text-white mb-5 shadow-card">
          <IconTab :name="actuel.icone" class="h-7 w-7" />
        </span>

        <h3 class="font-display font-bold text-xl mb-2">{{ actuel.titre }}</h3>
        <p v-if="actuel.description" class="text-forest-700/70 text-sm leading-relaxed mb-8 max-w-sm mx-auto">
          {{ actuel.description }}
        </p>

        <div class="flex gap-3 mt-2">
          <button v-if="step > 0" class="btn-outline flex-1" @click="precedent">Précédent</button>
          <button class="btn-accent flex-1" @click="suivant">
            {{ dernierePage ? 'Commencer' : 'Suivant' }}
            <IconTab name="arrow" class="h-4 w-4" />
          </button>
        </div>

        <button class="text-xs text-forest-400 mt-5 hover:text-forest-600 transition-colors" @click="passer">
          Passer l'introduction
        </button>
      </div>
    </div>
  </div>
</template>
