<script setup>
// `automatique` : true quand ce contenu est affiché par l'overlay global
// (components/ dans app.vue) suite à une vraie perte de connexion détectée,
// plutôt que par une visite directe de /hors-ligne.
defineProps({
  automatique: { type: Boolean, default: false }
})

const nouvelleTentative = () => {
  if (typeof window !== 'undefined') window.location.reload()
}
</script>

<template>
  <div class="min-h-screen flex items-center justify-center bg-brand-gradient-soft dark:bg-forest-900 px-5 py-12">
    <div class="w-full max-w-md text-center">
      <img src="/logo.png" alt="RETROUVA" class="h-14 w-14 mx-auto mb-6 object-contain" />

      <span class="inline-flex items-center gap-1.5 rounded-full bg-forest-800 text-white px-4 py-1.5 text-xs font-semibold uppercase tracking-wide mb-5">
        <IconTab name="wifiOff" class="h-3.5 w-3.5" /> Pas de connexion
      </span>

      <h1 class="text-2xl sm:text-3xl font-bold mb-3">Vous êtes hors ligne</h1>
      <p class="text-forest-700/70 leading-relaxed mb-8">
        Impossible de joindre RETROUVA pour le moment. Vérifiez votre Wi-Fi ou vos données mobiles,
        puis réessayez.
      </p>

      <div class="flex flex-col sm:flex-row items-center justify-center gap-3">
        <button class="btn-primary w-full sm:w-auto" @click="nouvelleTentative">
          <IconTab name="loader" class="h-4 w-4" /> Réessayer
        </button>
        <NuxtLink to="/" class="btn-outline w-full sm:w-auto">
          <IconTab name="home" class="h-4 w-4" /> Retour à l'accueil
        </NuxtLink>
      </div>

      <p v-if="automatique" class="text-xs text-forest-400 mt-6">
        Cet écran disparaîtra automatiquement dès que votre connexion sera rétablie.
      </p>
    </div>
  </div>
</template>
