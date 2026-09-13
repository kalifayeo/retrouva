<script setup>
const { objectTypes } = useObjectTypes()
const supabase = useSupabase()

const typeInfo = (id) => objectTypes.find(t => t.id === id) || { label: id, image: '' }

// On récupère un volume large en une seule fois (le flux public reste léger :
// aucune donnée sensible), puis on affiche progressivement par lots pour ne
// pas surcharger le rendu initial de la page.
const TOUT = ref([])
const chargement = ref(true)
const nbAffiches = ref(15)
const PAS = 15

const affiches = computed(() => TOUT.value.slice(0, nbAffiches.value))
const resteAAfficher = computed(() => TOUT.value.length > nbAffiches.value)

const chargerPlus = () => { nbAffiches.value += PAS }

onMounted(async () => {
  if (!supabase) { chargement.value = false; return }
  const { data } = await supabase.rpc('public_activity_feed', { p_limit: 200 })
  TOUT.value = data || []
  chargement.value = false
})

useHead({ title: "Activité récente — RETROUVA" })
</script>

<template>
  <div class="section py-8 md:py-12">
    <div class="container-app max-w-3xl">
      <NuxtLink to="/" class="inline-flex items-center gap-1.5 text-xs font-semibold text-forest-500 hover:text-forest-800 dark:hover:text-ivoire-50 transition-colors mb-5">
        <IconTab name="arrow" class="h-3.5 w-3.5 rotate-180" /> Retour à l'accueil
      </NuxtLink>

      <span class="eyebrow">En temps réel</span>
      <div class="section-divider my-3"></div>
      <h1 class="text-2xl md:text-3xl font-bold mb-2">Toute l'activité récente</h1>
      <p class="text-forest-700/70 mb-7 max-w-lg">
        L'ensemble des objets déclarés perdus, trouvés ou restitués sur RETROUVA, partout en Côte d'Ivoire.
      </p>

      <div class="card overflow-hidden">
        <div class="flex items-center gap-2.5 bg-forest-800 text-white px-5 py-4">
          <span class="h-2 w-2 rounded-full bg-savane-400 animate-pulse"></span>
          <span class="text-sm font-display font-semibold tracking-wide">Flux complet</span>
        </div>

        <div class="divide-y divide-forest-50">
          <template v-if="chargement">
            <div v-for="n in 6" :key="n" class="flex items-center gap-3 px-5 py-4 animate-pulse">
              <span class="h-10 w-10 shrink-0 rounded-full bg-forest-50"></span>
              <span class="flex-1 min-w-0 space-y-2">
                <span class="block h-3 w-2/3 rounded-full bg-forest-50"></span>
                <span class="block h-2.5 w-1/3 rounded-full bg-forest-50"></span>
              </span>
            </div>
          </template>

          <template v-else>
            <NuxtLink
              v-for="(r, i) in affiches"
              :key="r.id"
              v-reveal="{ delay: (i % PAS) * 40 }"
              to="/recherche"
              class="flex items-center gap-3 px-5 py-4 hover:bg-ivoire-100 dark:hover:bg-forest-800 transition-colors"
            >
              <span
                class="flex h-10 w-10 shrink-0 items-center justify-center rounded-full"
                :class="r.statut === 'restituee' ? 'bg-green-50 text-green-600' : (r.genre === 'perdu' ? 'bg-savane-50 text-savane-600' : 'bg-forest-50 text-forest-700')"
              >
                <IconTab :name="r.statut === 'restituee' ? 'handshake' : (r.genre === 'perdu' ? 'search' : 'check')" class="h-4 w-4" />
              </span>
              <span class="flex-1 min-w-0">
                <span class="block text-sm font-display font-semibold text-forest-800 truncate">
                  {{ typeInfo(r.object_type_id).label }} {{ libelleActivite(r) }}
                </span>
                <span class="flex items-center gap-1 text-xs text-forest-400 mt-0.5">
                  <IconTab name="pin" class="h-3 w-3" />
                  {{ r.commune ? `${r.commune}, ` : '' }}{{ r.ville }} · {{ tempsRelatif(r.created_at) }}
                </span>
              </span>
              <IconTab name="arrow" class="h-3.5 w-3.5 text-forest-300 shrink-0" />
            </NuxtLink>
            <p v-if="!TOUT.length" class="px-5 py-10 text-sm text-forest-400 text-center">
              Aucune déclaration pour le moment — soyez le premier à en publier une !
            </p>
          </template>
        </div>

        <div v-if="!chargement && resteAAfficher" class="p-4 border-t border-forest-50 dark:border-forest-800">
          <button class="btn-outline w-full" @click="chargerPlus">
            Charger plus <IconTab name="arrow" class="h-4 w-4 rotate-90" />
          </button>
        </div>
      </div>
    </div>
  </div>
</template>
