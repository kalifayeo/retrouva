<script setup>
definePageMeta({ middleware: 'auth' })

const { user } = useAuth()
const supabase = useSupabase()
const { objectTypes } = useObjectTypes()
const { infoStatut, etapeIndex, parcoursPerdu } = useStatuts()

const recherches = ref([])
const loading = ref(true)
const suppressionId = ref(null)

const labelType = (id) => objectTypes.find(t => t.id === id)?.label || id

const charger = async () => {
  loading.value = true
  const { data, error } = await supabase
    .from('lost_reports')
    .select('id, object_type_id, ville, commune, statut, description, created_at')
    .eq('user_id', user.value.id)
    .order('created_at', { ascending: false })

  if (!error) recherches.value = data || []
  loading.value = false
}

const supprimer = async (id) => {
  if (!confirm('Supprimer cette déclaration ? Les correspondances associées seront aussi supprimées.')) return
  suppressionId.value = id
  await supabase.from('lost_reports').delete().eq('id', id)
  suppressionId.value = null
  await charger()
}

const nbActives = computed(() => recherches.value.filter(r => ['active', 'correspondance', 'en_verification'].includes(r.statut)).length)
const nbRecuperes = computed(() => recherches.value.filter(r => r.statut === 'restituee').length)

onMounted(charger)
</script>

<template>
  <div class="section py-8 md:py-12">
    <div class="container-app">
      <div class="flex items-center justify-between mb-6">
        <div>
          <h1 class="text-2xl font-bold">Mes recherches</h1>
          <p class="text-sm text-forest-500 mt-1">RETROUVA continue de chercher tant qu'une recherche est active.</p>
        </div>
        <NuxtLink to="/perdu" class="btn-primary shrink-0"><IconTab name="plus" class="h-4 w-4" /> Nouvelle déclaration</NuxtLink>
      </div>

      <p v-if="loading" class="text-sm text-forest-500">Chargement…</p>

      <div v-else class="grid lg:grid-cols-3 gap-6">
        <!-- Colonne gauche : liste des recherches -->
        <div class="lg:col-span-2 space-y-3">
          <div v-if="recherches.length" class="space-y-3">
            <div v-for="r in recherches" :key="r.id" class="card p-4">
              <div class="flex items-start justify-between gap-3">
                <div class="min-w-0">
                  <p class="font-display font-semibold text-sm">{{ labelType(r.object_type_id) }}</p>
                  <p class="text-xs text-forest-400 mt-0.5 flex items-center gap-1">
                    <IconTab name="pin" class="h-3 w-3" />
                    {{ r.commune ? `${r.commune}, ` : '' }}{{ r.ville }} · depuis le
                    {{ new Date(r.created_at).toLocaleDateString('fr-FR') }}
                  </p>
                  <p v-if="r.description" class="text-xs text-forest-500 mt-1.5 line-clamp-2">{{ r.description }}</p>
                </div>
                <span :class="infoStatut(r.statut, 'perdu').badge" class="whitespace-nowrap shrink-0">
                  {{ infoStatut(r.statut, 'perdu').emoji }} {{ infoStatut(r.statut, 'perdu').label }}
                </span>
              </div>

              <!-- Frise d'étapes -->
              <div class="flex items-center gap-1 mt-4">
                <template v-for="(etape, i) in parcoursPerdu" :key="etape">
                  <span
                    class="h-1.5 flex-1 rounded-full"
                    :class="i <= etapeIndex(r.statut, 'perdu') ? 'bg-savane-500' : 'bg-forest-50'"
                  ></span>
                </template>
              </div>
              <p class="text-xs text-forest-400 mt-2">{{ infoStatut(r.statut, 'perdu').description }}</p>

              <div class="flex items-center justify-between mt-3 pt-3 border-t border-forest-50">
                <NuxtLink :to="r.statut === 'correspondance' ? '/resultats' : '/messagerie'" class="text-xs font-semibold text-savane-600">
                  {{ r.statut === 'correspondance' ? 'Voir la correspondance' : 'Voir les messages' }}
                </NuxtLink>
                <button
                  class="text-xs text-red-500 font-semibold hover:underline"
                  :disabled="suppressionId === r.id"
                  @click="supprimer(r.id)"
                >
                  {{ suppressionId === r.id ? '…' : 'Supprimer' }}
                </button>
              </div>
            </div>
          </div>

          <div v-else class="text-center py-16 text-forest-500 card">
            Vous n'avez pas encore de recherche active.
            <NuxtLink to="/perdu" class="text-savane-600 font-semibold block mt-2">Déclarer un objet perdu</NuxtLink>
          </div>
        </div>

        <!-- Colonne droite : résumé + conseils -->
        <div class="space-y-5">
          <div class="card p-5">
            <p class="text-[11px] font-bold uppercase tracking-widest text-forest-400 mb-4">Résumé</p>
            <div class="grid grid-cols-2 gap-4">
              <div>
                <div class="text-2xl font-display font-extrabold text-forest-800">{{ nbActives }}</div>
                <div class="text-xs text-forest-500 mt-0.5">Recherches actives</div>
              </div>
              <div>
                <div class="text-2xl font-display font-extrabold text-forest-800">{{ nbRecuperes }}</div>
                <div class="text-xs text-forest-500 mt-0.5">Objets récupérés</div>
              </div>
            </div>
          </div>

          <div class="card p-5 bg-forest-800 text-white">
            <p class="flex items-center gap-1.5 text-[11px] font-bold uppercase tracking-widest text-savane-400 mb-3">
              <IconTab name="shield" class="h-3 w-3" /> Comment ça marche
            </p>
            <p class="text-sm text-forest-100/80 leading-relaxed">
              Un score de correspondance élevé n'est jamais une preuve suffisante. RETROUVA vous
              demandera de confirmer des détails précis avant toute mise en relation avec le trouveur.
            </p>
          </div>

          <div class="card p-5">
            <p class="text-[11px] font-bold uppercase tracking-widest text-forest-400 mb-3">Besoin d'aide ?</p>
            <p class="text-sm text-forest-700/80 leading-relaxed mb-3">
              Consultez notre guide du parcours ou signalez une déclaration suspecte.
            </p>
            <div class="flex flex-col gap-2">
              <NuxtLink to="/comment-ca-marche" class="text-xs font-semibold text-savane-600">Comment ça marche →</NuxtLink>
              <NuxtLink to="/signalement" class="text-xs font-semibold text-savane-600">Signaler un problème →</NuxtLink>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
