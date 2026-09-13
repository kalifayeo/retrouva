<script setup>
const { estLente } = useConnexionReseau()
</script>

<template>
  <transition
    enter-active-class="transition duration-200 ease-out"
    enter-from-class="opacity-0 -translate-y-2"
    enter-to-class="opacity-100 translate-y-0"
    leave-active-class="transition duration-150 ease-in"
    leave-to-class="opacity-0 -translate-y-2"
  >
    <div
      v-if="estLente"
      class="fixed top-0 inset-x-0 z-[60] flex items-center justify-center gap-2 bg-savane-500 text-white text-xs font-medium py-1.5 px-4 pt-safe-top"
      role="status"
    >
      <IconTab name="loader" class="h-3.5 w-3.5 animate-spin shrink-0" />
      <span>Connexion lente détectée — l'affichage peut être plus long que d'habitude.</span>
    </div>
  </transition>
</template>
