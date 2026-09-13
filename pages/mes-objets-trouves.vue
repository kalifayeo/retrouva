<script setup>
definePageMeta({ middleware: 'auth' })

const { user } = useAuth()
const supabase = useSupabase()
const { objectTypes } = useObjectTypes()
const { infoStatut, etapeIndex, parcoursTrouve } = useStatuts()

const objets = ref([])
const loading = ref(true)
const suppressionId = ref(null)

const labelType = (id) => objectTypes.find(t => t.id === id)?.label || id

const charger = async () => {
  loading.value = true
  const { data, error } = await supabase
    .from('found_reports')
    .select('id, object_type_id, ville, commune, statut, description, created_at')
    .eq('user_id', user.value.id)
    .order('created_at', { ascending: false })

  if (!error) objets.value = data || []
  loading.value = false
}

const supprimer = async (id) => {
  if (!confirm('Supprimer cette déclaration ? Les correspondances associées seront aussi supprimées.')) return
  suppressionId.value = id
  await supabase.from('found_reports').delete().eq('id', id)
  suppressionId.value = null
  await charger()
}

const nbActifs = computed(() => objets.value.filter(o => ['active', 'correspondance', 'en_verification'].includes(o.statut)).length)
const nbRemis = computed(() => objets.value.filter(o => o.statut === 'restituee').length)

onMounted(charger)
</script>

<template>
  <div class="section py-8 md:py-12">
    <div class="container-app">
      <div class="flex items-center justify-between mb-6">
        <div>
          <h1 class="text-2xl font-bold">Mes objets trouvés</h1>
          <p class="text-sm text-forest-500 mt-1">Suivez la recherche du propriétaire pour chaque objet déclaré.</p>
        </div>
        <NuxtLink to="/trouve" class="btn-accent shrink-0"><IconTab name="plus" class="h-4 w-4" /> Nouvelle déclaration</NuxtLink>
      </div>

      <p v-if="loading" class="text-sm text-forest-500">Chargement…</p>

      <div v-else class="grid lg:grid-cols-3 gap-6">
        <!-- Colonne gauche : liste des déclarations -->
        <div class="lg:col-span-2 space-y-3">
          <div v-if="objets.length" class="space-y-3">
            <div v-for="o in objets" :key="o.id" class="card p-4">
              <div class="flex items-start justify-between gap-3">
                <div class="min-w-0">
                  <p class="font-display font-semibold text-sm">{{ labelType(o.object_type_id) }}</p>
                  <p class="text-xs text-forest-400 mt-0.5 flex items-center gap-1">
                    <IconTab name="pin" class="h-3 w-3" />
                    {{ o.commune ? `${o.commune}, ` : '' }}{{ o.ville }} · déclaré le
                    {{ new Date(o.created_at).toLocaleDateString('fr-FR') }}
                  </p>
                  <p v-if="o.description" class="text-xs text-forest-500 mt-1.5 line-clamp-2">{{ o.description }}</p>
                </div>
                <span :class="infoStatut(o.statut, 'trouve').badge" class="whitespace-nowrap shrink-0">
                  {{ infoStatut(o.statut, 'trouve').emoji }} {{ infoStatut(o.statut, 'trouve').label }}
                </span>
              </div>

              <!-- Frise d'étapes -->
              <div class="flex items-center gap-1 mt-4">
                <template v-for="(etape, i) in parcoursTrouve" :key="etape">
                  <span
                    class="h-1.5 flex-1 rounded-full"
                    :class="i <= etapeIndex(o.statut, 'trouve') ? 'bg-forest-600' : 'bg-forest-50'"
                  ></span>
                </template>
              </div>
              <p class="text-xs text-forest-400 mt-2">{{ infoStatut(o.statut, 'trouve').description }}</p>

              <div class="flex items-center justify-between mt-3 pt-3 border-t border-forest-50">
                <NuxtLink to="/messagerie" class="text-xs font-semibold text-savane-600">Voir les messages</NuxtLink>
                <button
                  class="text-xs text-red-500 font-semibold hover:underline"
                  :disabled="suppressionId === o.id"
                  @click="supprimer(o.id)"
                >
                  {{ suppressionId === o.id ? '…' : 'Supprimer' }}
                </button>
              </div>
            </div>
          </div>

          <div v-else class="text-center py-16 text-forest-500 card">
            Vous n'avez pas encore déclaré d'objet trouvé.
            <NuxtLink to="/trouve" class="text-savane-600 font-semibold block mt-2">Déclarer un objet trouvé</NuxtLink>
          </div>
        </div>

        <!-- Colonne droite : résumé + conseils -->
        <div class="space-y-5">
          <div class="card p-5">
            <p class="text-[11px] font-bold uppercase tracking-widest text-forest-400 mb-4">Résumé</p>
            <div class="grid grid-cols-2 gap-4">
              <div>
                <div class="text-2xl font-display font-extrabold text-forest-800">{{ nbActifs }}</div>
                <div class="text-xs text-forest-500 mt-0.5">Recherches actives</div>
              </div>
              <div>
                <div class="text-2xl font-display font-extrabold text-forest-800">{{ nbRemis }}</div>
                <div class="text-xs text-forest-500 mt-0.5">Objets remis</div>
              </div>
            </div>
          </div>

          <div class="card p-5 bg-forest-800 text-white">
            <p class="flex items-center gap-1.5 text-[11px] font-bold uppercase tracking-widest text-savane-400 mb-3">
              <IconTab name="shield" class="h-3 w-3" /> Bon à savoir
            </p>
            <p class="text-sm text-forest-100/80 leading-relaxed">
              Ne remettez jamais un objet à quelqu'un qui ne peut pas décrire ses caractéristiques
              précises. RETROUVA vérifie l'identité du demandeur avant toute mise en relation.
            </p>
          </div>

          <div class="card p-5">
            <p class="text-[11px] font-bold uppercase tracking-widest text-forest-400 mb-3">Options de remise</p>
            <ul class="space-y-2.5 text-sm text-forest-700/80">
              <li class="flex items-start gap-2"><IconTab name="handshake" class="h-4 w-4 text-forest-500 shrink-0 mt-0.5" /> Remise directe entre les deux personnes</li>
              <li class="flex items-start gap-2"><IconTab name="pin" class="h-4 w-4 text-forest-500 shrink-0 mt-0.5" /> Dépôt dans un point relais</li>
              <li class="flex items-start gap-2"><IconTab name="shield" class="h-4 w-4 text-forest-500 shrink-0 mt-0.5" /> Dépôt chez un partenaire RETROUVA</li>
            </ul>
            <NuxtLink to="/points-relais" class="text-xs font-semibold text-savane-600 mt-3 inline-block">Voir les points relais →</NuxtLink>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
