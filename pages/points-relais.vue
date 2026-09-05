<script setup>
const supabase = useSupabase()
const { villes } = useObjectTypes()

const points = ref([])
const loading = ref(true)
const villeChoisie = ref('')

const charger = async () => {
  loading.value = true
  if (!supabase) { loading.value = false; return }
  const { data } = await supabase
    .from('pickup_points')
    .select('id, nom, ville, commune, adresse, horaires, latitude, longitude')
    .eq('actif', true)
    .order('ville')
  points.value = data || []
  loading.value = false
}

const filtres = computed(() => villeChoisie.value ? points.value.filter(p => p.ville === villeChoisie.value) : points.value)
const villesDisponibles = computed(() => [...new Set(points.value.map(p => p.ville))])

onMounted(charger)
</script>

<template>
  <div class="section py-10 md:py-16">
    <div class="container-app">
      <span class="eyebrow">Réseau de confiance</span>
      <div class="section-divider my-3"></div>
      <h1 class="text-2xl md:text-3xl font-bold mb-2">Points relais &amp; partenaires</h1>
      <p class="text-forest-700/70 mb-8 max-w-2xl">
        Déposez ou récupérez un objet en toute sécurité auprès d'un partenaire vérifié : mairies,
        commissariats, centres commerciaux, gares... Ce réseau s'élargit progressivement.
      </p>

      <p v-if="loading" class="text-sm text-forest-500">Chargement…</p>

      <div v-else class="grid lg:grid-cols-3 gap-8">
        <!-- Colonne gauche : liste des points -->
        <div class="lg:col-span-2">
          <div v-if="villesDisponibles.length > 1" class="flex gap-2 mb-5 overflow-x-auto pb-1">
            <button
              class="text-xs font-semibold px-3.5 py-2 rounded-full whitespace-nowrap"
              :class="!villeChoisie ? 'bg-forest-800 text-white' : 'bg-ivoire-100 text-forest-600'"
              @click="villeChoisie = ''"
            >Toutes les villes</button>
            <button
              v-for="v in villesDisponibles"
              :key="v"
              class="text-xs font-semibold px-3.5 py-2 rounded-full whitespace-nowrap"
              :class="villeChoisie === v ? 'bg-forest-800 text-white' : 'bg-ivoire-100 text-forest-600'"
              @click="villeChoisie = v"
            >{{ v }}</button>
          </div>

          <div v-if="filtres.length" class="space-y-3">
            <div v-for="r in filtres" :key="r.id" class="card p-5 flex items-start gap-4">
              <span class="flex h-11 w-11 shrink-0 items-center justify-center rounded-full bg-forest-50 text-forest-700">
                <IconTab name="pin" class="h-5 w-5" />
              </span>
              <div class="min-w-0">
                <h3 class="font-display font-semibold">{{ r.nom }}</h3>
                <p class="text-sm text-forest-700/70">{{ r.adresse || r.commune }}{{ r.commune && r.adresse ? `, ${r.commune}` : '' }}, {{ r.ville }}</p>
                <p v-if="r.horaires" class="text-xs text-forest-400 mt-1 flex items-center gap-1">
                  <IconTab name="clock" class="h-3 w-3" /> {{ r.horaires }}
                </p>
              </div>
            </div>
          </div>

          <div v-else class="text-center py-16 text-forest-500 card">
            Réseau de points relais en cours de déploiement dans cette zone.
          </div>
        </div>

        <!-- Colonne droite : carte + infos -->
        <div class="space-y-5">
          <div class="card p-2 overflow-hidden">
            <ClientOnly>
              <RetrouvaCarte :interactive="false" hauteur="280px" />
            </ClientOnly>
          </div>

          <div class="card p-5">
            <p class="text-[11px] font-bold uppercase tracking-widest text-forest-400 mb-3">Comment ça marche</p>
            <ol class="space-y-2.5 text-sm text-forest-700/80">
              <li class="flex items-start gap-2"><span class="font-bold text-forest-500">1.</span> Après vérification, choisissez un point relais lors de la mise en relation.</li>
              <li class="flex items-start gap-2"><span class="font-bold text-forest-500">2.</span> Déposez ou récupérez l'objet aux horaires indiqués.</li>
              <li class="flex items-start gap-2"><span class="font-bold text-forest-500">3.</span> Confirmez la remise dans la messagerie RETROUVA.</li>
            </ol>
          </div>

          <div class="card p-5 bg-forest-800 text-white">
            <p class="flex items-center gap-1.5 text-[11px] font-bold uppercase tracking-widest text-savane-400 mb-3">
              <IconTab name="handshake" class="h-3 w-3" /> Devenir partenaire
            </p>
            <p class="text-sm text-forest-100/80 leading-relaxed">
              Mairie, commissariat, entreprise, école ou commerce : rejoignez le réseau RETROUVA
              en signalant votre intérêt via la messagerie de votre compte.
            </p>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
