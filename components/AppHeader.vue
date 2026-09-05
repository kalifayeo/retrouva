<script setup>
const { user, profile, signOut } = useAuth()

const open = ref(false)
const menuUtilisateur = ref(false)
const menuRef = ref(null)
const menuPlusRef = ref(null)
const menuPlus = ref(false)
let fermetureTimeout = null

onClickOutside(menuRef, () => { menuUtilisateur.value = false })
onClickOutside(menuPlusRef, () => { menuPlus.value = false })

const planifierFermeture = () => {
  fermetureTimeout = setTimeout(() => { menuUtilisateur.value = false }, 250)
}
const annulerFermeture = () => {
  if (fermetureTimeout) clearTimeout(fermetureTimeout)
}

// Liens principaux (toujours visibles) + liens secondaires regroupés par
// thème dans le menu "Plus", pour ne pas surcharger le header.
const liensPrincipaux = [
  { to: '/comment-ca-marche', label: 'Comment ça marche' },
  { to: '/carte', label: 'Carte' },
  { to: '/points-relais', label: 'Points relais' }
]
const groupesMenuPlus = [
  {
    titre: 'Découvrir',
    liens: [
      { to: '/evenements', label: 'Événements', icon: 'clock' },
      { to: '/securite', label: 'Sécurité & confidentialité', icon: 'shield' },
      { to: '/faq', label: 'FAQ', icon: 'chat' }
    ]
  },
  {
    titre: 'Assistance',
    liens: [
      { to: '/recherche', label: 'Rechercher un objet', icon: 'search' },
      { to: '/signalement', label: 'Signaler un problème', icon: 'bell' },
      { to: '/don', label: 'Faire un don', icon: 'handshake', accent: true }
    ]
  }
]

// "Administration" doit apparaître pour tout compte ayant un accès
// quelconque au panneau admin — donc aussi 'moderateur' depuis l'ajout de
// ce rôle (voir composables/useAdminPermissions.js), pas seulement
// administrateur/super_administrateur comme avant.
const estAdmin = computed(() => profile.value && rolesStaffAdmin.includes(profile.value.role))

// Petit repère visuel dans l'en-tête pour les comptes ayant un rôle
// particulier (accès admin, partenaire, agent relais) — même principe que
// le badge déjà affiché dans la barre latérale de /admin, mais visible
// partout sur le site pour ces comptes.
const libellesRole = {
  administrateur: 'Administrateur',
  super_administrateur: 'Super administrateur',
  moderateur: 'Modérateur',
  partenaire: 'Partenaire',
  agent_relais: 'Agent relais'
}
const libelleRole = computed(() => libellesRole[profile.value?.role] || '')

const notificationsNonLues = ref(0)
const messagesNonLus = ref(0)
const supabase = useSupabase()

const chargerNotifications = async () => {
  if (!supabase || !user.value) { notificationsNonLues.value = 0; messagesNonLus.value = 0; return }
  const { count } = await supabase
    .from('notifications')
    .select('id', { count: 'exact', head: true })
    .eq('user_id', user.value.id)
    .eq('lu', false)
  notificationsNonLues.value = count ?? 0

  const { count: countMessages } = await supabase
    .from('messages')
    .select('id', { count: 'exact', head: true })
    .eq('destinataire_id', user.value.id)
    .eq('lu', false)
  messagesNonLus.value = countMessages ?? 0
}

watch(user, chargerNotifications, { immediate: true })

const initiales = computed(() => {
  const source = profile.value?.nom_affiche || user.value?.email || 'RE'
  return source.slice(0, 2).toUpperCase()
})

const menuCompte = computed(() => {
  const items = [
    { label: 'Tableau de bord', to: '/dashboard', icon: 'card' },
    { label: 'Mon profil', to: '/profil', icon: 'user' },
    { label: 'Mes recherches', to: '/mes-recherches', icon: 'search' },
    { label: 'Mes objets trouvés', to: '/mes-objets-trouves', icon: 'plus' },
    { label: 'Messagerie', to: '/messagerie', icon: 'chat', badge: messagesNonLus.value }
  ]
  if (profile.value?.role === 'partenaire') items.push({ label: 'Espace partenaire', to: '/partenaire', icon: 'handshake' })
  if (profile.value?.role === 'agent_relais') items.push({ label: 'Espace agent relais', to: '/agent-relais', icon: 'handshake' })
  if (estAdmin.value) items.push({ label: 'Administration', to: '/admin', icon: 'shield' })
  return items
})

const logout = async () => {
  menuUtilisateur.value = false
  await signOut()
  navigateTo('/')
}

const recherche = ref('')
const lancerRecherche = () => {
  if (!recherche.value.trim()) return
  open.value = false
  navigateTo({ path: '/recherche', query: { q: recherche.value.trim() } })
}
</script>

<template>
  <header class="sticky top-0 z-50 bg-ivoire-100/90 dark:bg-forest-900/95 backdrop-blur border-b border-forest-50 dark:border-forest-800 pt-safe-top">
    <div class="section container-app flex items-center justify-between h-16 gap-3">
      <NuxtLink to="/" class="flex items-center gap-2 shrink-0">
        <img src="/logo.png" alt="RETROUVA" class="h-9 w-9 object-contain" />
        <span class="font-display font-extrabold text-lg tracking-tight">
          <span class="text-forest-800 dark:text-ivoire-50">RETROUV</span><span class="text-savane-500">A</span>
        </span>
      </NuxtLink>

      <nav class="hidden lg:flex items-center gap-5 shrink-0">
        <NuxtLink
          v-for="l in liensPrincipaux"
          :key="l.to"
          :to="l.to"
          class="text-sm font-medium text-forest-700 dark:text-ivoire-200 hover:text-savane-600 transition-colors whitespace-nowrap"
        >
          {{ l.label }}
        </NuxtLink>

        <div ref="menuPlusRef" class="relative">
          <button
            class="flex items-center gap-1 text-sm font-medium text-forest-700 dark:text-ivoire-200 hover:text-savane-600 transition-colors"
            @click="menuPlus = !menuPlus"
          >
            Plus
            <IconTab name="arrow" class="h-3 w-3 rotate-90 transition-transform" :class="{ '-rotate-90': menuPlus }" />
          </button>
          <transition
            enter-active-class="transition duration-150 ease-out"
            enter-from-class="opacity-0 scale-95 -translate-y-2"
            enter-to-class="opacity-100 scale-100 translate-y-0"
            leave-active-class="transition duration-100 ease-in"
            leave-to-class="opacity-0 scale-95"
          >
            <div v-if="menuPlus" class="absolute left-1/2 -translate-x-1/2 mt-4 w-[28rem] max-w-[90vw] bg-white shadow-floating border border-forest-50 overflow-hidden">
              <div class="h-1.5 bg-brand-gradient"></div>
              <div class="grid grid-cols-2 divide-x divide-forest-50 p-4">
                <div v-for="groupe in groupesMenuPlus" :key="groupe.titre" class="px-2 first:pl-0 last:pr-0">
                  <p class="px-2 pb-2.5 text-[11px] font-bold uppercase tracking-wide text-forest-400">{{ groupe.titre }}</p>
                  <NuxtLink
                    v-for="l in groupe.liens" :key="l.to" :to="l.to"
                    class="flex items-center gap-2.5 px-2 py-2.5 text-sm rounded-lg transition-all duration-150 hover:bg-forest-50 dark:hover:bg-forest-800 hover:translate-x-1 group/item"
                    :class="l.accent ? 'text-savane-600 font-semibold' : 'text-forest-700 dark:text-ivoire-200'"
                    @click="menuPlus = false"
                  >
                    <span
                      class="flex h-8 w-8 shrink-0 items-center justify-center rounded-full transition-colors duration-150"
                      :class="l.accent ? 'bg-savane-50 text-savane-600 group-hover/item:bg-savane-100' : 'bg-forest-50 text-forest-500 group-hover/item:bg-white dark:group-hover/item:bg-forest-700'"
                    >
                      <IconTab :name="l.icon" class="h-4 w-4" />
                    </span>
                    {{ l.label }}
                  </NuxtLink>
                </div>
              </div>
            </div>
          </transition>
        </div>
      </nav>

      <form class="hidden lg:flex items-center flex-1 max-w-xs mx-2" @submit.prevent="lancerRecherche">
        <div class="flex items-center gap-2 w-full bg-white border border-forest-100 px-3.5 py-2 focus-within:border-savane-400 transition-colors">
          <IconTab name="search" class="h-4 w-4 text-forest-400 shrink-0" />
          <input
            v-model="recherche"
            type="text"
            placeholder="Rechercher un objet…"
            class="w-full text-sm outline-none placeholder:text-forest-300 bg-transparent"
          />
        </div>
      </form>

      <div class="hidden lg:flex items-center gap-3 shrink-0">
        <ThemeToggle />
        <template v-if="user">
          <NuxtLink to="/dashboard" class="text-sm font-medium text-forest-700 dark:text-ivoire-200 hover:text-savane-600 transition-colors whitespace-nowrap">
            Tableau de bord
          </NuxtLink>
          <NuxtLink to="/notifications" class="relative p-2 text-forest-700 hover:text-savane-600 transition-colors" aria-label="Notifications">
            <IconTab name="bell" class="h-5 w-5" />
            <span v-if="notificationsNonLues > 0" class="absolute top-1 right-1 h-2 w-2 rounded-full bg-savane-500"></span>
          </NuxtLink>
          <NuxtLink to="/declarer" class="btn-accent !px-5 !py-2.5 text-sm whitespace-nowrap"><IconTab name="plus" class="h-4 w-4" /> Déclarer un objet</NuxtLink>
          <div ref="menuRef" class="relative" @mouseleave="planifierFermeture" @mouseenter="annulerFermeture">
            <button
              class="flex h-10 w-10 items-center justify-center rounded-full bg-forest-800 text-white font-display font-bold text-sm tap-target"
              @click="menuUtilisateur = !menuUtilisateur"
            >
              {{ initiales }}
            </button>
            <transition
              enter-active-class="transition duration-100 ease-out"
              enter-from-class="opacity-0 scale-95"
              enter-to-class="opacity-100 scale-100"
              leave-active-class="transition duration-75 ease-in"
              leave-to-class="opacity-0 scale-95"
            >
              <div
                v-if="menuUtilisateur"
                class="absolute right-0 mt-2 w-56 bg-white shadow-floating border border-forest-50 overflow-hidden"
                @click="menuUtilisateur = false"
              >
                <div class="px-4 py-3 border-b border-forest-50">
                  <p class="text-sm font-semibold text-forest-800 truncate flex items-center gap-1.5">
                    {{ profile?.nom_affiche || 'Mon compte' }}
                    <BadgeVerifie v-if="profile?.role === 'utilisateur_verifie'" size="xs" />
                  </p>
                  <p class="text-xs text-forest-400 truncate">{{ user.email }}</p>
                  <span v-if="libelleRole" class="badge-green !py-0.5 !px-2 text-[10px] mt-1.5">{{ libelleRole }}</span>
                </div>
                <NuxtLink
                  v-for="m in menuCompte"
                  :key="m.to"
                  :to="m.to"
                  class="flex items-center justify-between gap-2.5 px-4 py-2.5 text-sm text-forest-700 dark:text-ivoire-200 transition-all duration-150 hover:bg-forest-50 dark:hover:bg-forest-800 hover:pl-5"
                >
                  <span class="flex items-center gap-2.5">
                    <IconTab :name="m.icon" class="h-4 w-4 text-forest-400" /> {{ m.label }}
                  </span>
                  <span v-if="m.badge" class="flex h-5 min-w-[1.25rem] items-center justify-center rounded-full bg-savane-500 px-1 text-[11px] font-bold text-white">
                    {{ m.badge > 9 ? '9+' : m.badge }}
                  </span>
                </NuxtLink>
                <button
                  class="flex w-full items-center gap-2.5 px-4 py-2.5 text-sm text-red-600 hover:bg-red-50 dark:hover:bg-red-950/40 border-t border-forest-50"
                  @click="logout"
                >
                  <IconTab name="close" class="h-4 w-4" /> Se déconnecter
                </button>
              </div>
            </transition>
          </div>
        </template>

        <template v-else>
          <NuxtLink to="/connexion" class="btn-ghost !px-4 !py-2 text-sm"><IconTab name="user" class="h-4 w-4" /> Se connecter</NuxtLink>
          <NuxtLink to="/declarer" class="btn-accent !px-5 !py-2.5 text-sm"><IconTab name="plus" class="h-4 w-4" /> Déclarer un objet</NuxtLink>
        </template>
      </div>

      <!-- Mobile : icône recherche juste à côté du menu à trois traits -->
      <div class="flex items-center gap-1 lg:hidden shrink-0">
        <ThemeToggle />
        <NuxtLink to="/recherche" class="tap-target p-2 text-forest-800 dark:text-ivoire-100" aria-label="Rechercher">
          <IconTab name="search" class="h-5 w-5" />
        </NuxtLink>
        <button class="tap-target p-2 text-forest-800 dark:text-ivoire-100" @click="open = !open" aria-label="Menu">
          <IconTab :name="open ? 'close' : 'menu'" class="h-6 w-6" />
        </button>
      </div>
    </div>

    <!-- Rétro-éclairage derrière le panneau mobile : ferme le menu au clic -->
    <transition
      enter-active-class="transition duration-150 ease-out"
      enter-from-class="opacity-0"
      enter-to-class="opacity-100"
      leave-active-class="transition duration-100 ease-in"
      leave-to-class="opacity-0"
    >
      <div
        v-if="open"
        class="lg:hidden fixed inset-0 top-16 z-40 bg-forest-900/50 backdrop-blur-[1px]"
        @click="open = false"
      ></div>
    </transition>

    <transition
      enter-active-class="transition duration-150 ease-out"
      enter-from-class="opacity-0 -translate-y-2"
      enter-to-class="opacity-100 translate-y-0"
      leave-active-class="transition duration-100 ease-in"
      leave-to-class="opacity-0"
    >
      <div v-if="open" class="lg:hidden relative z-40 border-t border-forest-50 dark:border-forest-800 bg-white dark:bg-forest-900 max-h-[calc(100vh-4rem)] overflow-y-auto overscroll-contain pb-24">
        <!-- Bloc recherche -->
        <div class="px-5 pt-4 pb-4 border-b border-forest-50 dark:border-forest-800">
          <form class="flex items-center gap-2 border border-forest-100 dark:border-forest-700 px-3.5 py-2.5" @submit.prevent="lancerRecherche">
            <IconTab name="search" class="h-4 w-4 text-forest-400 shrink-0" />
            <input v-model="recherche" type="text" placeholder="Rechercher un objet…" class="w-full text-sm outline-none placeholder:text-forest-300 bg-transparent" />
          </form>
        </div>

        <!-- Bloc navigation principale -->
        <div class="border-b border-forest-50 dark:border-forest-800 py-1">
          <NuxtLink
            v-for="l in liensPrincipaux"
            :key="l.to"
            :to="l.to"
            class="flex items-center gap-3 px-5 py-3 text-sm font-semibold text-forest-800 dark:text-ivoire-50 active:bg-forest-50 dark:active:bg-forest-800 transition-colors"
            @click="open = false"
          >
            {{ l.label }}
          </NuxtLink>
        </div>

        <!-- Blocs thématiques : mêmes groupes que le menu "Plus" sur desktop -->
        <div
          v-for="groupe in groupesMenuPlus"
          :key="groupe.titre"
          class="border-b border-forest-50 dark:border-forest-800 py-2"
        >
          <p class="px-5 pb-1.5 text-[11px] font-bold uppercase tracking-wide text-forest-400">{{ groupe.titre }}</p>
          <NuxtLink
            v-for="l in groupe.liens"
            :key="l.to"
            :to="l.to"
            class="flex items-center gap-3 px-5 py-2.5 text-sm active:bg-forest-50 dark:active:bg-forest-800 transition-colors"
            :class="l.accent ? 'text-savane-600 font-semibold' : 'text-forest-700 dark:text-ivoire-200'"
            @click="open = false"
          >
            <span
              class="flex h-7 w-7 shrink-0 items-center justify-center"
              :class="l.accent ? 'bg-savane-50 text-savane-600' : 'bg-forest-50 text-forest-500'"
            >
              <IconTab :name="l.icon" class="h-3.5 w-3.5" />
            </span>
            {{ l.label }}
          </NuxtLink>
        </div>

        <!-- Bloc compte -->
        <template v-if="user">
          <div class="flex items-center gap-3 px-5 py-4 border-b border-forest-50 dark:border-forest-800">
            <span class="flex h-11 w-11 shrink-0 items-center justify-center rounded-full bg-forest-800 text-white font-display font-bold text-sm">
              {{ initiales }}
            </span>
            <div class="min-w-0">
              <p class="text-sm font-semibold text-forest-800 dark:text-ivoire-50 truncate flex items-center gap-1.5">
                {{ profile?.nom_affiche || 'Mon compte' }}
                <BadgeVerifie v-if="profile?.role === 'utilisateur_verifie'" size="xs" />
              </p>
              <p class="text-xs text-forest-400 truncate">{{ user.email }}</p>
              <span v-if="libelleRole" class="badge-green !py-0.5 !px-2 text-[10px] mt-1.5">{{ libelleRole }}</span>
            </div>
          </div>
          <div class="border-b border-forest-50 dark:border-forest-800 py-1">
            <NuxtLink
              v-for="m in menuCompte"
              :key="m.to"
              :to="m.to"
              class="flex items-center justify-between gap-3 px-5 py-2.5 text-sm text-forest-700 dark:text-ivoire-200 active:bg-forest-50 dark:active:bg-forest-800 transition-colors"
              @click="open = false"
            >
              <span class="flex items-center gap-3">
                <IconTab :name="m.icon" class="h-4 w-4 text-forest-400" /> {{ m.label }}
              </span>
              <span v-if="m.badge" class="flex h-5 min-w-[1.25rem] items-center justify-center rounded-full bg-savane-500 px-1 text-[11px] font-bold text-white">
                {{ m.badge > 9 ? '9+' : m.badge }}
              </span>
            </NuxtLink>
          </div>
          <button
            class="w-full flex items-center gap-3 px-5 py-3 text-sm text-red-600 active:bg-red-50 dark:active:bg-red-950/40 transition-colors border-b border-forest-50 dark:border-forest-800"
            @click="open = false; logout()"
          >
            <IconTab name="close" class="h-4 w-4" /> Se déconnecter
          </button>
        </template>
        <NuxtLink
          v-else
          to="/connexion"
          class="flex items-center justify-center gap-2 px-5 py-4 text-sm font-semibold text-forest-800 dark:text-ivoire-50 border-b border-forest-50 dark:border-forest-800"
          @click="open = false"
        >
          <IconTab name="user" class="h-4 w-4" /> Se connecter
        </NuxtLink>

        <!-- Appel à l'action toujours visible en bas du panneau -->
        <div class="px-5 pt-4">
          <NuxtLink to="/declarer" class="btn-accent w-full" @click="open = false">
            <IconTab name="plus" class="h-4 w-4" /> Déclarer un objet
          </NuxtLink>
        </div>
      </div>
    </transition>
  </header>
</template>
