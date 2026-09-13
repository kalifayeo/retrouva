<script setup>
const props = defineProps({
  error: { type: Object, default: () => ({}) }
})

const code = computed(() => props.error?.statusCode || 404)
const estIntrouvable = computed(() => code.value === 404)

const titre = computed(() =>
  estIntrouvable.value ? "Page introuvable" : "Une erreur est survenue"
)
const message = computed(() =>
  estIntrouvable.value
    ? "La page que vous cherchez n'existe pas ou a été déplacée."
    : "Quelque chose s'est mal passé de notre côté. Nos équipes ont été informées."
)

const revenirAccueil = () => clearError({ redirect: '/' })
</script>

<template>
  <div class="min-h-screen flex items-center justify-center bg-brand-gradient-soft dark:bg-forest-900 px-5 py-12">
    <div class="w-full max-w-md text-center">
      <img src="/logo.png" alt="RETROUVA" class="h-14 w-14 mx-auto mb-6 object-contain" />

      <span class="inline-flex items-center gap-1.5 rounded-full bg-forest-800 text-white px-4 py-1.5 text-xs font-semibold uppercase tracking-wide mb-5">
        Erreur {{ code }}
      </span>

      <h1 class="text-2xl sm:text-3xl font-bold mb-3">{{ titre }}</h1>
      <p class="text-forest-700/70 leading-relaxed mb-8">{{ message }}</p>

      <div class="flex flex-col sm:flex-row items-center justify-center gap-3">
        <button class="btn-primary w-full sm:w-auto" @click="revenirAccueil">
          <IconTab name="home" class="h-4 w-4" /> Retour à l'accueil
        </button>
        <NuxtLink to="/signalement" class="btn-outline w-full sm:w-auto">
          <IconTab name="bell" class="h-4 w-4" /> Signaler le problème
        </NuxtLink>
      </div>
    </div>
  </div>
</template>
