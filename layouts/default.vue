<script setup>
const route = useRoute()

const tabs = [
  { to: '/', label: 'Accueil', icon: 'home' },
  { to: '/resultats', label: 'Rechercher', icon: 'search' },
  { to: '/declarer', label: 'Déclarer', icon: 'plus', central: true },
  { to: '/messagerie', label: 'Messages', icon: 'chat' },
  { to: '/profil', label: 'Profil', icon: 'user' }
]

const isActive = (to) => route.path === to
</script>

<template>
  <div class="min-h-screen flex flex-col bg-ivoire-100 dark:bg-forest-900 transition-colors duration-200">
    <ConfigWarningBanner />
    <AppHeader />
    <SitePopup />
    <IntroVideo />
    <OnboardingIntro />
    <FloatingActions />

    <main class="flex-1 pb-24 md:pb-0 pt-safe-top">
      <slot />
    </main>

    <AppFooter class="hidden md:block" />

    <!-- Barre de navigation mobile façon app native -->
    <nav
      class="md:hidden fixed bottom-0 inset-x-0 z-40 bg-white/95 dark:bg-forest-900/95 backdrop-blur border-t border-forest-50 dark:border-forest-800 pb-safe-bottom"
      aria-label="Navigation principale"
    >
      <div class="flex items-stretch justify-between px-2">
        <NuxtLink
          v-for="tab in tabs"
          :key="tab.to"
          :to="tab.to"
          class="relative flex flex-1 flex-col items-center justify-center gap-1 py-2.5 tap-target"
        >
          <template v-if="tab.central">
            <span class="absolute -top-6 flex h-14 w-14 items-center justify-center rounded-full bg-brand-gradient shadow-floating">
              <IconTab name="plus" class="h-6 w-6 text-white" />
            </span>
            <span class="mt-8 text-[11px] font-semibold text-forest-800 dark:text-ivoire-100">{{ tab.label }}</span>
          </template>
          <template v-else>
            <IconTab :name="tab.icon" class="h-5 w-5" :class="isActive(tab.to) ? 'text-savane-500' : 'text-forest-300 dark:text-forest-500'" />
            <span
              class="text-[11px] font-medium"
              :class="isActive(tab.to) ? 'text-forest-800 dark:text-ivoire-100 font-semibold' : 'text-forest-300 dark:text-forest-500'"
            >
              {{ tab.label }}
            </span>
          </template>
        </NuxtLink>
      </div>
    </nav>
  </div>
</template>
