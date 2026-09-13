<script setup>
// Page autonome (pas de header/footer/nav) affichée lorsque le mode
// maintenance est activé depuis /admin/contenu. Voir middleware/00.maintenance.global.js.
//
// Sécurité : cette page ne doit rien révéler ni permettre d'atteindre
// d'autres parties du site pendant une maintenance — pas de lien vers
// l'administration (retiré volontairement), pas d'indexation par les
// moteurs de recherche, et aucune information technique affichée.
definePageMeta({ layout: false })
useHead({
  title: 'Maintenance en cours — RETROUVA',
  meta: [{ name: 'robots', content: 'noindex, nofollow' }]
})

const supabase = useSupabase()
const configured = useSupabaseConfigured()
const message = ref('')

onMounted(async () => {
  if (!configured) return
  const { data } = await supabase
    .from('site_settings')
    .select('valeur')
    .eq('cle', 'maintenance_message')
    .maybeSingle()
  message.value = data?.valeur || ''
})

// "Réessayer" doit revenir à l'accueil et non recharger /maintenance elle-
// même : le middleware de maintenance ignore volontairement /maintenance
// pour éviter une boucle infinie (voir 00.maintenance.global.js), donc
// recharger cette page ne revérifierait jamais si le mode a été désactivé.
// Un rechargement complet vers "/" relance l'app à zéro et laisse le
// middleware retrouver l'état réel : accueil si la maintenance est bien
// terminée, ou retour ici sinon.
const reessayer = () => { window.location.href = '/' }
</script>

<template>
  <div class="min-h-screen flex items-center justify-center bg-brand-gradient-soft dark:bg-forest-900 px-5 py-12 relative overflow-hidden">
    <div class="pointer-events-none absolute -top-24 -right-24 h-72 w-72 rounded-full bg-savane-300/20 blur-3xl"></div>
    <div class="pointer-events-none absolute -bottom-32 -left-16 h-80 w-80 rounded-full bg-forest-300/20 blur-3xl"></div>

    <div class="w-full max-w-md text-center relative">
      <img src="/logo.png" alt="RETROUVA" class="h-16 w-16 mx-auto mb-6 object-contain maintenance-float" />

      <span class="inline-flex items-center gap-1.5 rounded-full bg-forest-800 text-white px-4 py-1.5 text-xs font-semibold uppercase tracking-wide mb-5">
        <span class="h-1.5 w-1.5 rounded-full bg-savane-400 animate-pulse"></span>
        Maintenance en cours
      </span>

      <h1 class="text-2xl sm:text-3xl font-bold mb-3">
        RETROUVA revient très vite
      </h1>
      <p class="text-forest-700/70 leading-relaxed mb-2">
        Nous effectuons actuellement une mise à jour du site pour améliorer votre expérience.
        Merci de votre patience, le service sera de nouveau disponible sous peu.
      </p>
      <p v-if="message" class="text-forest-700/70 leading-relaxed mb-2 font-medium">
        {{ message }}
      </p>

      <div class="mt-8 flex flex-col items-center gap-3">
        <button class="btn-primary" @click="reessayer">
          <IconTab name="clock" class="h-4 w-4" /> Réessayer
        </button>
      </div>
    </div>
  </div>
</template>

<style scoped>
.maintenance-float {
  animation: maintenance-float-kf 6s ease-in-out infinite;
}
@keyframes maintenance-float-kf {
  0%, 100% { transform: translateY(0); }
  50% { transform: translateY(-8px); }
}
@media (prefers-reduced-motion: reduce) {
  .maintenance-float { animation: none; }
}
</style>
