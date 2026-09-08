<script setup>
const configured = useSupabaseConfigured()
</script>

<template>
  <div v-if="!configured" class="bg-savane-500 text-white text-xs sm:text-sm text-center py-2 px-4">
    ⚠️ Supabase non configuré : créez un fichier <code class="font-mono">.env</code> à partir de
    <code class="font-mono">.env.example</code> avec vos clés, puis relancez <code class="font-mono">npm run dev</code>.
    Voir le README, section « Installation initiale ».
  </div>
</template>
