<script setup>
definePageMeta({ middleware: 'admin', layout: 'admin' })

const supabase = useSupabase()

const messages = ref([])
const loading = ref(true)
const conversationActive = ref(null)
const reponse = ref('')
const envoiEnCours = ref(false)
const zoneMessages = ref(null)
let intervalle = null

const charger = async () => {
  const { data } = await supabase
    .from('support_messages')
    .select('*')
    .order('created_at', { ascending: true })
  messages.value = data || []
  loading.value = false
}

// Regroupe les messages par conversation, avec le dernier message et le
// nombre de messages non lus envoyés par le visiteur.
const conversations = computed(() => {
  const map = new Map()
  for (const m of messages.value) {
    if (!map.has(m.conversation_id)) map.set(m.conversation_id, { id: m.conversation_id, nom: m.nom_visiteur, messages: [], nonLus: 0 })
    const conv = map.get(m.conversation_id)
    conv.messages.push(m)
    if (m.nom_visiteur) conv.nom = m.nom_visiteur
    if (m.auteur === 'utilisateur' && !m.lu) conv.nonLus++
  }
  return [...map.values()].sort((a, b) => {
    const da = a.messages[a.messages.length - 1]?.created_at || ''
    const db = b.messages[b.messages.length - 1]?.created_at || ''
    return db.localeCompare(da)
  })
})

const messagesConversation = computed(() =>
  conversationActive.value ? (conversations.value.find(c => c.id === conversationActive.value)?.messages || []) : []
)

const scrollerEnBas = async () => {
  await nextTick()
  if (zoneMessages.value) zoneMessages.value.scrollTop = zoneMessages.value.scrollHeight
}

const ouvrirConversation = async (id) => {
  conversationActive.value = id
  await scrollerEnBas()
  const nonLus = messages.value.filter(m => m.conversation_id === id && m.auteur === 'utilisateur' && !m.lu)
  if (nonLus.length) {
    await supabase.from('support_messages').update({ lu: true }).in('id', nonLus.map(m => m.id))
    await charger()
  }
}

const envoyerReponse = async () => {
  const contenu = reponse.value.trim()
  if (!contenu || !conversationActive.value) return
  envoiEnCours.value = true
  await supabase.from('support_messages').insert({
    conversation_id: conversationActive.value,
    auteur: 'admin',
    contenu,
    lu: true
  })
  reponse.value = ''
  envoiEnCours.value = false
  await charger()
  await scrollerEnBas()
}

onMounted(() => {
  charger()
  intervalle = setInterval(charger, 6000)
})
onBeforeUnmount(() => { if (intervalle) clearInterval(intervalle) })
</script>

<template>
  <div class="section py-8 md:py-12">
    <div class="container-app max-w-4xl">
      <h1 class="text-2xl font-bold mb-1">Support technique</h1>
      <p class="text-forest-700/70 mb-6">
        Conversations démarrées depuis le bouton de chat flottant, présent sur toutes les pages du site.
      </p>

      <p v-if="loading" class="text-sm text-forest-500">Chargement…</p>
      <div v-else class="grid md:grid-cols-[280px_1fr] gap-4 md:h-[32rem]">
        <div class="card p-2 overflow-y-auto space-y-1">
          <button
            v-for="c in conversations" :key="c.id" type="button"
            class="w-full text-left rounded-xl px-3 py-2.5 transition-colors"
            :class="conversationActive === c.id ? 'bg-forest-800 text-white' : 'hover:bg-forest-50'"
            @click="ouvrirConversation(c.id)"
          >
            <p class="text-sm font-semibold truncate flex items-center gap-1.5">
              {{ c.nom || 'Visiteur anonyme' }}
              <span v-if="c.nonLus" class="badge-orange !py-0 !px-1.5 text-[10px]">{{ c.nonLus }}</span>
            </p>
            <p class="text-xs truncate" :class="conversationActive === c.id ? 'text-ivoire-100/70' : 'text-forest-400'">
              {{ c.messages[c.messages.length - 1]?.contenu }}
            </p>
          </button>
          <p v-if="!conversations.length" class="text-center py-10 text-sm text-forest-500">Aucune conversation pour le moment.</p>
        </div>

        <div class="card p-0 flex flex-col overflow-hidden">
          <template v-if="conversationActive">
            <div ref="zoneMessages" class="flex-1 overflow-y-auto p-4 space-y-3 bg-forest-50/40">
              <div
                v-for="m in messagesConversation" :key="m.id"
                class="max-w-[75%] rounded-2xl px-3.5 py-2.5 text-sm"
                :class="m.auteur === 'admin' ? 'bg-forest-800 text-white ml-auto rounded-br-sm' : 'bg-white shadow-card mr-auto rounded-bl-sm'"
              >
                {{ m.contenu }}
              </div>
            </div>
            <form class="flex items-center gap-2 border-t border-forest-100 p-3 shrink-0" @submit.prevent="envoyerReponse">
              <input v-model="reponse" type="text" class="input-field !py-2.5 flex-1" placeholder="Répondre au visiteur…" />
              <button type="submit" class="btn-accent !px-4 !py-2.5" :disabled="envoiEnCours || !reponse.trim()">Envoyer</button>
            </form>
          </template>
          <div v-else class="flex-1 flex items-center justify-center text-sm text-forest-400 p-8 text-center">
            Sélectionnez une conversation pour y répondre.
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
