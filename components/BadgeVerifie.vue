<script setup>
// Badge de confiance, purement visuel : aucune donnée sensible, aucune
// policy RLS à toucher. S'affiche partout où le nom d'un compte
// 'utilisateur_verifie' apparaît (voir profil.vue et AppHeader.vue).
defineProps({
  size: { type: String, default: 'sm' } // 'sm' | 'xs'
})
</script>

<template>
  <span
    class="inline-flex items-center justify-center rounded-full bg-forest-600 text-white shrink-0"
    :class="size === 'xs' ? 'h-3.5 w-3.5' : 'h-4.5 w-4.5'"
    style="width: 1.05rem; height: 1.05rem;"
    title="Compte vérifié"
    aria-label="Compte vérifié"
  >
    <svg viewBox="0 0 20 20" fill="currentColor" class="h-full w-full p-[3px]">
      <path fill-rule="evenodd" d="M16.704 5.29a.75.75 0 010 1.06l-7.5 7.5a.75.75 0 01-1.06 0l-3.5-3.5a.75.75 0 111.06-1.06l2.97 2.97 6.97-6.97a.75.75 0 011.06 0z" clip-rule="evenodd" />
    </svg>
  </span>
</template>
