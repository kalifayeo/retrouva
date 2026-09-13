<script setup>
// Overlay hors-ligne global : monté ici (au-dessus de NuxtLayout) pour
// couvrir toute l'application quel que soit le layout de la page affichée,
// sans perdre l'état de la page en cours (contrairement à une redirection
// vers /hors-ligne, on revient pile où l'utilisateur était dès la
// reconnexion).
const { estEnLigne } = useConnexionReseau()

// Notifications push réelles (app mobile uniquement, voir
// composables/usePushNotifications.js) : enregistrement dès qu'un compte
// est connecté, et à nouveau si l'utilisateur se reconnecte avec un autre
// compte sur le même appareil.
const { user } = useAuth()
const { initialiserPushNotifications, reinitialiserPushNotifications } = usePushNotifications()
watch(user, (u) => {
  if (u) initialiserPushNotifications()
  else reinitialiserPushNotifications()
}, { immediate: true })
</script>

<template>
  <ConnexionBanniere />
  <NuxtLayout>
    <NuxtPage />
  </NuxtLayout>
  <div v-if="!estEnLigne" class="fixed inset-0 z-[100]">
    <HorsLigneContenu automatique />
  </div>
  <CookieConsent />
</template>
