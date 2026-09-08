<script setup>
defineProps({
  label: { type: String, required: true },
  icon: { type: String, default: 'card' },
  image: { type: String, default: '' },
  selected: { type: Boolean, default: false }
})
defineEmits(['select'])
</script>

<template>
  <button
    type="button"
    class="flex flex-col items-center gap-2 border-2 px-3 py-4 text-center transition-all tap-target"
    :class="selected
      ? 'border-savane-500 bg-savane-50 shadow-card'
      : 'border-forest-50 bg-white hover:border-forest-100'"
    @click="$emit('select')"
  >
    <span
      v-if="image"
      class="flex h-14 w-14 items-center justify-center overflow-hidden bg-ivoire-100"
      :class="selected ? 'ring-2 ring-savane-500' : ''"
    >
      <img :src="image" :alt="label" class="h-full w-full object-cover" loading="lazy" />
    </span>
    <span
      v-else
      class="flex h-11 w-11 items-center justify-center rounded-full"
      :class="selected ? 'bg-savane-500 text-white' : 'bg-forest-50 text-forest-700'"
    >
      <IconTab :name="icon" class="h-5 w-5" />
    </span>
    <span class="text-xs font-semibold text-forest-800 leading-tight">{{ label }}</span>
  </button>
</template>
