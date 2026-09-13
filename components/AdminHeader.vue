<script setup>
const route = useRoute()
const supabase = useSupabase()
const nav = useAdminNav()
const { profile } = useAuth()

const initiale = computed(() => (profile.value?.nom_affiche || profile.value?.telephone || 'A').trim().charAt(0).toUpperCase())

const titre = computed(() => {
  const item = [...nav].reverse().find(n => n.exact ? route.path === n.to : route.path.startsWith(n.to))
  return item?.label || 'Administration'
})

// ---------------------------------------------------------------------
// ÉLÉMENTS IMPORTANTS — quelques compteurs toujours visibles, quel que
// soit l'écran admin ouvert, pour repérer en un coup d'œil ce qui
// attend une action.
// ---------------------------------------------------------------------
const compteurs = reactive({ signalements: 0, support: 0, dons: 0 })
const chargerCompteurs = async () => {
  if (!supabase) return
  const [{ count: signalements }, { count: dons }, { data: support }] = await Promise.all([
    supabase.from('reports').select('id', { count: 'exact', head: true }).eq('statut', 'ouvert'),
    supabase.from('donations').select('id', { count: 'exact', head: true }).eq('statut', 'en_attente'),
    supabase.from('support_messages').select('id, auteur, lu')
  ])
  compteurs.signalements = signalements || 0
  compteurs.dons = dons || 0
  compteurs.support = (support || []).filter(m => m.auteur === 'utilisateur' && !m.lu).length
}

let intervalle = null
onMounted(() => {
  chargerCompteurs()
  intervalle = setInterval(chargerCompteurs, 30000)
})
onBeforeUnmount(() => { if (intervalle) clearInterval(intervalle) })
</script>

<template>
  <header class="hidden lg:flex sticky top-0 z-20 items-center justify-between gap-4 h-16 px-6 bg-white/90 dark:bg-forest-900/90 backdrop-blur border-b border-forest-100 dark:border-forest-800">
    <h1 class="font-display font-bold text-lg text-forest-800 dark:text-ivoire-100 truncate">{{ titre }}</h1>

    <div class="flex items-center gap-2 shrink-0">
      <NuxtLink
        to="/admin/signalements"
        class="flex items-center gap-1.5 rounded-full px-3 py-1.5 text-xs font-semibold transition-colors"
        :class="compteurs.signalements ? 'bg-red-50 text-red-600 dark:bg-red-500/10' : 'bg-forest-50 text-forest-400 dark:bg-forest-800'"
      >
        <IconTab name="bell" class="h-3.5 w-3.5" /> {{ compteurs.signalements }} signalement{{ compteurs.signalements === 1 ? '' : 's' }}
      </NuxtLink>
      <NuxtLink
        to="/admin/support"
        class="flex items-center gap-1.5 rounded-full px-3 py-1.5 text-xs font-semibold transition-colors"
        :class="compteurs.support ? 'bg-savane-50 text-savane-700 dark:bg-savane-500/10' : 'bg-forest-50 text-forest-400 dark:bg-forest-800'"
      >
        <IconTab name="chat" class="h-3.5 w-3.5" /> {{ compteurs.support }} message{{ compteurs.support === 1 ? '' : 's' }}
      </NuxtLink>
      <NuxtLink
        to="/admin/dons"
        class="flex items-center gap-1.5 rounded-full px-3 py-1.5 text-xs font-semibold transition-colors"
        :class="compteurs.dons ? 'bg-forest-50 text-forest-700 dark:bg-forest-800 dark:text-ivoire-100' : 'bg-forest-50 text-forest-400 dark:bg-forest-800'"
      >
        <IconTab name="gift" class="h-3.5 w-3.5" /> {{ compteurs.dons }} don{{ compteurs.dons === 1 ? '' : 's' }} en attente
      </NuxtLink>

      <span class="w-px h-6 bg-forest-100 dark:bg-forest-800 mx-1"></span>
      <ThemeToggle />

      <span class="w-px h-6 bg-forest-100 dark:bg-forest-800 mx-1"></span>
      <div class="flex items-center gap-2">
        <span class="flex h-8 w-8 items-center justify-center rounded-full bg-forest-800 dark:bg-savane-500 text-white text-xs font-bold shrink-0">
          {{ initiale }}
        </span>
        <div class="leading-tight hidden xl:block">
          <p class="text-xs font-semibold text-forest-800 dark:text-ivoire-100 truncate max-w-[9rem]">{{ profile?.nom_affiche || profile?.telephone || 'Compte admin' }}</p>
          <p class="text-[10px] text-forest-400 truncate max-w-[9rem]">{{ profile?.role }}</p>
        </div>
      </div>
    </div>
  </header>
</template>
