<script setup>
const route = useRoute()
const { profile, signOut } = useAuth()
const open = ref(false)

const nav = useAdminNav()

const initiale = computed(() => (profile.value?.nom_affiche || profile.value?.telephone || 'A').trim().charAt(0).toUpperCase())

const estActif = (item) => item.exact ? route.path === item.to : route.path.startsWith(item.to)

watch(() => route.path, () => { open.value = false })

const logout = async () => {
  await signOut()
  navigateTo('/')
}
</script>

<template>
  <!-- Barre mobile -->
  <div class="lg:hidden sticky top-0 z-40 flex items-center justify-between bg-forest-800 text-white px-4 h-14 pt-safe-top">
    <button class="p-2 -ml-2 tap-target" @click="open = true" aria-label="Menu admin">
      <IconTab name="menu" class="h-5 w-5" />
    </button>
    <div class="flex items-center gap-2 min-w-0">
      <span class="flex h-7 w-7 items-center justify-center rounded-full bg-savane-500 text-white text-[11px] font-bold shrink-0">
        {{ initiale }}
      </span>
      <span class="font-display font-semibold text-sm truncate max-w-[9rem]">{{ profile?.nom_affiche || profile?.telephone || 'Administration' }}</span>
    </div>
    <div class="flex items-center gap-1">
      <ThemeToggle on-dark />
      <NuxtLink to="/" class="p-2 -mr-1 text-forest-100/70" aria-label="Retour au site">
        <IconTab name="close" class="h-5 w-5" />
      </NuxtLink>
    </div>
  </div>

  <!-- Tiroir mobile : présent dans la page UNIQUEMENT quand ouvert, jamais
       mélangé avec la barre desktop. -->
  <div v-if="open" class="lg:hidden fixed inset-0 z-50 flex">
    <div class="absolute inset-0 bg-forest-900/60" @click="open = false"></div>
    <aside class="relative z-10 h-full w-72 max-w-[85vw] bg-forest-800 text-white flex flex-col overflow-y-auto pt-safe-top">
      <div class="flex items-center justify-between px-5 h-16 border-b border-white/10 shrink-0">
        <span class="flex items-center gap-2">
          <img src="/logo.png" class="h-8 w-8 object-contain" alt="RETROUVA" />
          <span class="font-display font-bold text-sm">Administration</span>
        </span>
        <button class="p-1" @click="open = false" aria-label="Fermer">
          <IconTab name="close" class="h-5 w-5" />
        </button>
      </div>

      <nav class="flex-1 overflow-y-auto px-3 py-4 space-y-1">
        <NuxtLink
          v-for="item in nav" :key="item.to" :to="item.to"
          class="flex items-center gap-3 rounded-xl px-3 py-2.5 text-sm font-medium transition-colors"
          :class="estActif(item) ? 'bg-savane-500 text-white' : 'text-forest-100/80 hover:bg-white/10'"
        >
          <IconTab :name="item.icon" class="h-4 w-4 shrink-0" /> {{ item.label }}
        </NuxtLink>
      </nav>

      <div class="px-3 py-4 border-t border-white/10 space-y-1 shrink-0">
        <p class="px-3 text-xs font-semibold text-white truncate">{{ profile?.nom_affiche || profile?.telephone || 'Compte admin' }}</p>
        <p class="px-3 text-xs text-forest-100/50 mb-1">{{ profile?.role }}</p>
        <NuxtLink to="/" class="flex items-center gap-3 rounded-xl px-3 py-2.5 text-sm text-forest-100/80 hover:bg-white/10">
          <IconTab name="arrow" class="h-4 w-4 rotate-180" /> Retour au site
        </NuxtLink>
        <button class="w-full flex items-center gap-3 rounded-xl px-3 py-2.5 text-sm text-red-300 hover:bg-white/10" @click="logout">
          <IconTab name="close" class="h-4 w-4" /> Se déconnecter
        </button>
      </div>
    </aside>
  </div>

  <!-- Barre latérale desktop : jamais affichée sur mobile, toujours affichée
       à partir de lg. Élément totalement distinct du tiroir mobile. -->
  <aside class="hidden lg:flex fixed top-0 left-0 z-30 h-full w-72 bg-forest-800 text-white flex-col pt-safe-top">
    <div class="flex items-center px-5 h-16 border-b border-white/10 shrink-0">
      <NuxtLink to="/" class="flex items-center gap-2">
        <img src="/logo.png" class="h-8 w-8 object-contain" alt="RETROUVA" />
        <span class="font-display font-bold text-sm">Administration</span>
      </NuxtLink>
    </div>

    <nav class="flex-1 overflow-y-auto px-3 py-4 space-y-1">
      <NuxtLink
        v-for="item in nav" :key="item.to" :to="item.to"
        class="flex items-center gap-3 rounded-xl px-3 py-2.5 text-sm font-medium transition-colors"
        :class="estActif(item) ? 'bg-savane-500 text-white' : 'text-forest-100/80 hover:bg-white/10'"
      >
        <IconTab :name="item.icon" class="h-4 w-4 shrink-0" /> {{ item.label }}
      </NuxtLink>
    </nav>

    <div class="px-3 py-4 border-t border-white/10 space-y-1 shrink-0">
      <p class="px-3 text-xs font-semibold text-white truncate">{{ profile?.nom_affiche || profile?.telephone || 'Compte admin' }}</p>
      <p class="px-3 text-xs text-forest-100/50 mb-1">{{ profile?.role }}</p>
      <NuxtLink to="/" class="flex items-center gap-3 rounded-xl px-3 py-2.5 text-sm text-forest-100/80 hover:bg-white/10">
        <IconTab name="arrow" class="h-4 w-4 rotate-180" /> Retour au site
      </NuxtLink>
      <button class="w-full flex items-center gap-3 rounded-xl px-3 py-2.5 text-sm text-red-300 hover:bg-white/10" @click="logout">
        <IconTab name="close" class="h-4 w-4" /> Se déconnecter
      </button>
    </div>
  </aside>
</template>
