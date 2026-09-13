<script setup>
definePageMeta({ middleware: 'auth' })

const { user } = useAuth()
const supabase = useSupabase()

const items = ref([])
const loading = ref(true)
const filtre = ref('toutes')

const icones = { correspondance: 'check', message: 'chat', statut: 'bell', systeme: 'bell', verification: 'shield', restitution: 'handshake' }

const onglets = [
  { id: 'toutes', label: 'Toutes' },
  { id: 'non_lues', label: 'Non lues' },
  { id: 'correspondance', label: 'Correspondances' },
  { id: 'verification', label: 'Vérifications' },
  { id: 'restitution', label: 'Récupérations' }
]

const charger = async () => {
  loading.value = true
  if (!supabase || !user.value) { loading.value = false; return }
  const { data } = await supabase
    .from('notifications')
    .select('id, titre, corps, type, lien, lu, created_at')
    .eq('user_id', user.value.id)
    .order('created_at', { ascending: false })
  items.value = data || []
  loading.value = false

  const nonLues = (data || []).filter(n => !n.lu).map(n => n.id)
  if (nonLues.length) {
    await supabase.from('notifications').update({ lu: true }).in('id', nonLues)
    items.value = items.value.map(n => ({ ...n, lu: true }))
  }
}

const filtrees = computed(() => {
  if (filtre.value === 'toutes') return items.value
  if (filtre.value === 'non_lues') return items.value.filter(n => !n.lu)
  return items.value.filter(n => n.type === filtre.value)
})

const nbNonLues = computed(() => items.value.filter(n => !n.lu).length)
const nbCorrespondances = computed(() => items.value.filter(n => n.type === 'correspondance').length)

const relatif = (date) => {
  const diffH = Math.round((Date.now() - new Date(date).getTime()) / 3600000)
  if (diffH < 1) return "à l'instant"
  if (diffH < 24) return `il y a ${diffH} h`
  return `il y a ${Math.round(diffH / 24)} j`
}

const ouvrir = (n) => {
  if (n.lien) navigateTo(n.lien)
}

const supprimer = async (n) => {
  items.value = items.value.filter(i => i.id !== n.id)
  await supabase.from('notifications').delete().eq('id', n.id)
}

const toutSupprimer = async () => {
  if (!confirm('Supprimer toutes les notifications ?')) return
  const ids = items.value.map(i => i.id)
  items.value = []
  if (ids.length) await supabase.from('notifications').delete().in('id', ids)
}

onMounted(charger)
</script>

<template>
  <div class="section py-8 md:py-12">
    <div class="container-app">
      <div class="grid lg:grid-cols-3 gap-8">
        <!-- Colonne gauche : liste -->
        <div class="lg:col-span-2">
          <div class="flex items-center justify-between mb-4">
            <h1 class="text-2xl font-bold">Notifications</h1>
            <button v-if="items.length" class="text-xs text-red-500 font-semibold hover:underline" @click="toutSupprimer">
              Tout supprimer
            </button>
          </div>

          <div class="flex gap-2 mb-6 overflow-x-auto pb-1">
            <button
              v-for="o in onglets"
              :key="o.id"
              class="text-xs font-semibold px-3.5 py-2 rounded-full whitespace-nowrap transition-colors"
              :class="filtre === o.id ? 'bg-forest-800 text-white' : 'bg-ivoire-100 text-forest-600 hover:bg-ivoire-200 dark:hover:bg-forest-700'"
              @click="filtre = o.id"
            >
              {{ o.label }}
            </button>
          </div>

          <p v-if="loading" class="text-sm text-forest-500">Chargement…</p>

          <div v-else-if="filtrees.length" class="card divide-y divide-forest-50">
            <div
              v-for="n in filtrees"
              :key="n.id"
              class="flex gap-3 px-5 py-4 group"
              :class="[n.lien ? 'cursor-pointer hover:bg-ivoire-50 dark:hover:bg-forest-800/60' : '', { 'bg-forest-50/50': !n.lu }]"
              @click="ouvrir(n)"
            >
              <span class="flex h-10 w-10 shrink-0 items-center justify-center rounded-full bg-forest-50 text-forest-700">
                <IconTab :name="icones[n.type] || 'bell'" class="h-5 w-5" />
              </span>
              <div class="flex-1 min-w-0">
                <p class="text-sm font-semibold text-forest-800">{{ n.titre }}</p>
                <p class="text-sm text-forest-700">{{ n.corps }}</p>
                <p class="text-xs text-forest-400 mt-1">{{ relatif(n.created_at) }}</p>
              </div>
              <button
                class="text-forest-300 hover:text-red-500 opacity-0 group-hover:opacity-100 transition-opacity shrink-0"
                @click.stop="supprimer(n)"
              >
                <IconTab name="close" class="h-4 w-4" />
              </button>
            </div>
          </div>

          <div v-else class="text-center py-16 text-forest-500 card">
            Aucune notification {{ filtre !== 'toutes' ? 'dans cette catégorie' : 'pour le moment' }}.
          </div>
        </div>

        <!-- Colonne droite -->
        <div class="space-y-5">
          <div class="card p-5">
            <p class="text-[11px] font-bold uppercase tracking-widest text-forest-400 mb-4">Résumé</p>
            <div class="grid grid-cols-2 gap-4">
              <div>
                <div class="text-2xl font-display font-extrabold text-forest-800">{{ nbNonLues }}</div>
                <div class="text-xs text-forest-500 mt-0.5">Non lues</div>
              </div>
              <div>
                <div class="text-2xl font-display font-extrabold text-forest-800">{{ nbCorrespondances }}</div>
                <div class="text-xs text-forest-500 mt-0.5">Correspondances</div>
              </div>
            </div>
          </div>

          <div class="card p-5">
            <p class="text-[11px] font-bold uppercase tracking-widest text-forest-400 mb-3">Types de notifications</p>
            <ul class="space-y-2.5 text-sm text-forest-700/80">
              <li class="flex items-center gap-2"><IconTab name="check" class="h-4 w-4 text-forest-500" /> Correspondance détectée</li>
              <li class="flex items-center gap-2"><IconTab name="shield" class="h-4 w-4 text-forest-500" /> Vérification à traiter ou validée</li>
              <li class="flex items-center gap-2"><IconTab name="handshake" class="h-4 w-4 text-forest-500" /> Remise / récupération confirmée</li>
              <li class="flex items-center gap-2"><IconTab name="chat" class="h-4 w-4 text-forest-500" /> Nouveau message</li>
            </ul>
          </div>

          <NuxtLink to="/messagerie" class="card-hover p-5 flex items-center gap-3 block">
            <span class="flex h-10 w-10 items-center justify-center rounded-full bg-savane-50 text-savane-600 shrink-0">
              <IconTab name="chat" class="h-5 w-5" />
            </span>
            <div>
              <p class="text-sm font-display font-semibold text-forest-800">Ma messagerie</p>
              <p class="text-xs text-forest-400">Voir toutes mes conversations</p>
            </div>
          </NuxtLink>
        </div>
      </div>
    </div>
  </div>
</template>
