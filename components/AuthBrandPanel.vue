<script setup>
defineProps({
  titre: { type: String, required: true },
  texte: { type: String, required: true },
  image: { type: String, default: '' }
})

const points = [
  { icon: 'shield', label: 'Données sensibles jamais publiées' },
  { icon: 'check', label: 'Vérification avant toute restitution' },
  { icon: 'handshake', label: 'Réseau de points relais partenaires' }
]
</script>

<template>
  <div class="auth-brand">
    <img v-if="image" :src="image" alt="" class="absolute inset-0 h-full w-full object-cover" />
    <div v-if="image" class="absolute inset-0 bg-gradient-to-t from-forest-900/95 via-forest-800/85 to-savane-600/40"></div>
    <template v-else>
      <div class="auth-brand-blob auth-brand-blob-1"></div>
      <div class="auth-brand-blob auth-brand-blob-2"></div>
    </template>

    <div class="relative z-10 flex flex-col h-full justify-between p-8 lg:p-10">
      <NuxtLink to="/" class="flex items-center gap-2">
        <img src="/logo.png" alt="RETROUVA" class="h-9 w-9 object-contain" />
        <span class="font-display font-extrabold text-lg text-white">
          RETROUV<span class="text-savane-400">A</span>
        </span>
      </NuxtLink>

      <div>
        <h2 class="text-xl lg:text-2xl font-display font-bold text-white mb-2">{{ titre }}</h2>
        <p class="text-forest-100/80 text-sm leading-relaxed max-w-sm">{{ texte }}</p>

        <ul class="mt-6 space-y-2.5">
          <li v-for="p in points" :key="p.label" class="flex items-center gap-3 text-sm text-forest-100/90">
            <span class="flex h-7 w-7 shrink-0 items-center justify-center rounded-full bg-white/15 backdrop-blur-sm">
              <IconTab :name="p.icon" class="h-3.5 w-3.5 text-savane-400" />
            </span>
            {{ p.label }}
          </li>
        </ul>
      </div>

      <p class="text-xs text-forest-100/50">Trouver. Connecter. Restituer.</p>
    </div>
  </div>
</template>
