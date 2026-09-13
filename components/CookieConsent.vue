<script setup>
const { consentement, charger, toutAccepter, toutRefuser, enregistrer } = useCookieConsent()
const afficherPanneau = ref(false)
const fonctionnelChoix = ref(true)

onMounted(charger)

const ouvrirPersonnalisation = () => { afficherPanneau.value = true }
const validerPersonnalisation = () => {
  enregistrer({ fonctionnel: fonctionnelChoix.value })
  afficherPanneau.value = false
}
</script>

<template>
  <div
    v-if="consentement === null"
    class="fixed inset-x-0 bottom-0 z-[70] p-2 sm:p-5"
    role="dialog"
    aria-modal="false"
    aria-label="Préférences de cookies"
  >
    <div class="container-app max-w-3xl mx-auto rounded-xl sm:rounded-2xl border border-forest-100 bg-white dark:bg-forest-800 shadow-floating p-3 sm:p-6">
      <div v-if="!afficherPanneau" class="flex flex-col sm:flex-row sm:items-center gap-2.5 sm:gap-4">
        <div class="flex items-start gap-2.5 sm:gap-3 flex-1">
          <span class="hidden xs:flex sm:flex h-7 w-7 sm:h-9 sm:w-9 shrink-0 items-center justify-center rounded-full bg-forest-50 text-forest-700">
            <IconTab name="shield" class="h-3.5 w-3.5 sm:h-4 sm:w-4" />
          </span>
          <p class="text-xs sm:text-sm text-forest-700/80 leading-snug sm:leading-relaxed">
            RETROUVA utilise des cookies nécessaires au fonctionnement du site et, avec votre accord,
            des cookies de confort (pop-up d'information, vidéo et écran de bienvenue). Vous pouvez
            revenir sur votre choix à tout moment depuis notre
            <NuxtLink to="/cookies" class="underline font-semibold text-forest-800 dark:text-ivoire-100">politique de cookies</NuxtLink>.
          </p>
        </div>
        <div class="flex flex-wrap gap-1.5 sm:gap-2 sm:shrink-0">
          <button type="button" class="btn-ghost !px-3 !py-1.5 !text-xs sm:!px-4 sm:!py-2 sm:!text-sm" @click="ouvrirPersonnalisation">
            Personnaliser
          </button>
          <button type="button" class="btn-outline !px-3 !py-1.5 !text-xs sm:!px-4 sm:!py-2 sm:!text-sm" @click="toutRefuser">
            Refuser
          </button>
          <button type="button" class="btn-primary !px-3 !py-1.5 !text-xs sm:!px-4 sm:!py-2 sm:!text-sm" @click="toutAccepter">
            Tout accepter
          </button>
        </div>
      </div>

      <div v-else class="space-y-3 sm:space-y-4">
        <h3 class="font-display font-semibold text-sm sm:text-base">Personnaliser les cookies</h3>

        <div class="flex items-center justify-between gap-3 sm:gap-4 rounded-xl border border-forest-100 p-2.5 sm:p-3.5">
          <div>
            <p class="font-semibold text-xs sm:text-sm">Nécessaires</p>
            <p class="text-[11px] sm:text-xs text-forest-500 mt-0.5">Toujours actifs — connexion, sécurité, préférence de thème.</p>
          </div>
          <input type="checkbox" checked disabled class="h-4 w-4 sm:h-5 sm:w-5 rounded border-forest-200 accent-forest-800 shrink-0" />
        </div>

        <div class="flex items-center justify-between gap-3 sm:gap-4 rounded-xl border border-forest-100 p-2.5 sm:p-3.5">
          <div>
            <p class="font-semibold text-xs sm:text-sm">Confort</p>
            <p class="text-[11px] sm:text-xs text-forest-500 mt-0.5">Pop-up d'information, vidéo et écran de bienvenue à la première visite.</p>
          </div>
          <input v-model="fonctionnelChoix" type="checkbox" class="h-4 w-4 sm:h-5 sm:w-5 rounded border-forest-200 accent-forest-800 shrink-0" />
        </div>

        <div class="flex justify-end gap-2 pt-1">
          <button type="button" class="btn-ghost !px-3 !py-1.5 !text-xs sm:!px-4 sm:!py-2 sm:!text-sm" @click="afficherPanneau = false">Retour</button>
          <button type="button" class="btn-primary !px-3 !py-1.5 !text-xs sm:!px-4 sm:!py-2 sm:!text-sm" @click="validerPersonnalisation">Enregistrer mes choix</button>
        </div>
      </div>
    </div>
  </div>
</template>
