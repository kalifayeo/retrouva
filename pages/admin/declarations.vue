<script setup>
definePageMeta({ middleware: 'admin', layout: 'admin' })

const supabase = useSupabase()
const { profile } = useAuth()
const { objectTypes, villes, communesAbidjan } = useObjectTypes()

// Un modérateur peut consulter et masquer (changer le statut) une
// déclaration, mais pas la supprimer définitivement — pouvoir réservé à
// administrateur/super_administrateur. Confort d'usage seulement : la RLS
// (voir migration_23) ne donne de toute façon aucun droit de suppression
// au rôle moderateur.
const peutSupprimer = computed(() => profile.value && ['administrateur', 'super_administrateur'].includes(profile.value.role))

const onglet = ref('perdu') // 'perdu' | 'trouve'
const perdues = ref([])
const trouvees = ref([])
const loading = ref(true)
const editionId = ref(null)
const form = reactive({ ville: '', commune: '', date: '', statut: '' })
const saving = ref(false)

const labelType = (id) => objectTypes.find(t => t.id === id)?.label || id
const table = computed(() => onglet.value === 'perdu' ? 'lost_reports' : 'found_reports')
const liste = computed(() => onglet.value === 'perdu' ? perdues.value : trouvees.value)

const statutStyle = {
  active: 'badge bg-forest-50 text-forest-500',
  correspondance: 'badge-green',
  en_verification: 'badge-orange',
  restituee: 'badge-green',
  expiree: 'badge bg-forest-50 text-forest-400',
  archivee: 'badge bg-forest-50 text-forest-400'
}

const statuts = ['active', 'correspondance', 'en_verification', 'restituee', 'expiree', 'archivee']

const charger = async () => {
  loading.value = true
  const [lost, found] = await Promise.all([
    supabase.from('lost_reports').select('id, object_type_id, ville, commune, date_perte, statut, created_at').order('created_at', { ascending: false }).limit(100),
    supabase.from('found_reports').select('id, object_type_id, ville, commune, date_trouvaille, statut, created_at').order('created_at', { ascending: false }).limit(100)
  ])
  perdues.value = lost.data || []
  trouvees.value = found.data || []
  loading.value = false
}

const ouvrirEdition = (d) => {
  editionId.value = d.id
  form.ville = d.ville
  form.commune = d.commune || ''
  form.date = d.date_perte || d.date_trouvaille
  form.statut = d.statut
}

const annuler = () => { editionId.value = null }

const enregistrer = async (d) => {
  saving.value = true
  const dateCol = onglet.value === 'perdu' ? 'date_perte' : 'date_trouvaille'
  await supabase.from(table.value).update({
    ville: form.ville,
    commune: form.commune || null,
    [dateCol]: form.date,
    statut: form.statut
  }).eq('id', d.id)
  saving.value = false
  editionId.value = null
  await charger()
}

const supprimer = async (id) => {
  if (!confirm('Supprimer définitivement cette déclaration ? Les correspondances associées seront aussi supprimées.')) return
  await supabase.from(table.value).delete().eq('id', id)
  await charger()
}

onMounted(charger)
</script>

<template>
  <div class="section py-8 md:py-12">
    <div class="container-app">
      <h1 class="text-2xl font-bold mb-1">Déclarations</h1>
      <p class="text-forest-700/70 mb-6">Toutes les déclarations d'objets perdus et trouvés.</p>

      <div class="flex rounded-full bg-forest-50 p-1 mb-6 text-sm font-semibold w-fit">
        <button class="rounded-full px-5 py-2" :class="onglet === 'perdu' ? 'bg-white shadow-card text-forest-800' : 'text-forest-400'" @click="onglet = 'perdu'; editionId = null">
          Perdues ({{ perdues.length }})
        </button>
        <button class="rounded-full px-5 py-2" :class="onglet === 'trouve' ? 'bg-white shadow-card text-forest-800' : 'text-forest-400'" @click="onglet = 'trouve'; editionId = null">
          Trouvées ({{ trouvees.length }})
        </button>
      </div>

      <p v-if="loading" class="text-sm text-forest-500">Chargement…</p>

      <div v-else class="space-y-3">
        <div v-for="d in liste" :key="d.id" class="card p-4">
          <div class="flex items-center justify-between gap-3">
            <div class="min-w-0">
              <p class="font-medium text-sm">{{ labelType(d.object_type_id) }}</p>
              <p class="text-xs text-forest-400">
                {{ d.commune ? `${d.commune}, ` : '' }}{{ d.ville }} ·
                {{ new Date(d.date_perte || d.date_trouvaille).toLocaleDateString('fr-FR') }}
              </p>
            </div>
            <div class="flex items-center gap-3 shrink-0">
              <span :class="statutStyle[d.statut] || 'badge'">{{ d.statut }}</span>
              <button class="text-xs text-forest-600 font-semibold hover:underline" @click="editionId === d.id ? annuler() : ouvrirEdition(d)">
                {{ editionId === d.id ? 'Fermer' : 'Modifier' }}
              </button>
              <button v-if="peutSupprimer" class="text-xs text-red-500 font-semibold hover:underline" @click="supprimer(d.id)">
                Supprimer
              </button>
            </div>
          </div>

          <div v-if="editionId === d.id" class="mt-4 pt-4 border-t border-forest-50 grid sm:grid-cols-2 gap-3">
            <div>
              <label class="label-field">Ville</label>
              <select v-model="form.ville" class="input-field !py-2 text-sm">
                <option v-for="v in villes" :key="v" :value="v">{{ v }}</option>
              </select>
            </div>
            <div>
              <label class="label-field">Commune</label>
              <select v-model="form.commune" class="input-field !py-2 text-sm">
                <option value="">—</option>
                <option v-for="c in communesAbidjan" :key="c" :value="c">{{ c }}</option>
              </select>
            </div>
            <div>
              <label class="label-field">Date</label>
              <input v-model="form.date" type="date" class="input-field !py-2 text-sm" />
            </div>
            <div>
              <label class="label-field">Statut</label>
              <select v-model="form.statut" class="input-field !py-2 text-sm">
                <option v-for="s in statuts" :key="s" :value="s">{{ s }}</option>
              </select>
            </div>
            <div class="sm:col-span-2">
              <button class="btn-primary text-sm !py-2" :disabled="saving" @click="enregistrer(d)">
                {{ saving ? 'Enregistrement…' : 'Enregistrer' }}
              </button>
            </div>
          </div>
        </div>

        <p v-if="!liste.length" class="card text-center py-10 text-forest-500">
          Aucune déclaration pour le moment.
        </p>
      </div>
    </div>
  </div>
</template>
