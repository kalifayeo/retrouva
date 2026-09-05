<script setup>
const props = defineProps({
  // Pour les barres toujours sur fond foncé (ex. admin), où les classes
  // "dark:" habituelles ne suffisent pas puisque le fond ne dépend pas
  // du thème choisi par l'utilisateur.
  onDark: { type: Boolean, default: false }
})
const { theme, basculer } = useTheme()
</script>

<template>
  <button
    class="flex h-9 w-9 items-center justify-center rounded-full tap-target transition-colors"
    :class="props.onDark
      ? 'text-forest-100/80 hover:bg-white/10'
      : 'text-forest-600 dark:text-ivoire-100 hover:bg-forest-50 dark:hover:bg-forest-800'"
    :aria-label="theme === 'dark' ? 'Passer au mode clair' : 'Passer au mode sombre'"
    @click="basculer"
  >
    <IconTab :name="theme === 'dark' ? 'sun' : 'moon'" class="h-5 w-5" />
  </button>
</template>
