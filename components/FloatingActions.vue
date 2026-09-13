<script setup>
const supabase = useSupabase()
const configured = useSupabaseConfigured()
const { user, profile } = useAuth()

const ouvert = ref(false)
const scrolled = ref(false)

const onScroll = () => { scrolled.value = window.scrollY > 400 }
onMounted(() => {
  window.addEventListener('scroll', onScroll, { passive: true })
  onScroll()
})
onBeforeUnmount(() => window.removeEventListener('scroll', onScroll))

const remonter = () => window.scrollTo({ top: 0, behavior: 'smooth' })

// ---------------------------------------------------------------------
// WHATSAPP — numéro géré par l'admin dans /admin/contenu
// ---------------------------------------------------------------------
const numeroWhatsapp = ref('2250797676545')
const lienWhatsapp = computed(() => {
  const numero = numeroWhatsapp.value.replace(/[^0-9]/g, '')
  const texte = encodeURIComponent("Bonjour, j'ai besoin d'aide sur RETROUVA.")
  return `https://wa.me/${numero}?text=${texte}`
})

// ---------------------------------------------------------------------
// CHAT SUPPORT — une conversation par visiteur (profil connecté, sinon
// identifiant anonyme gardé dans le navigateur)
// ---------------------------------------------------------------------
const chatOuvert = ref(false)
const conversationId = ref(null)
const messages = ref([])
const nouveauMessage = ref('')
const envoiEnCours = ref(false)
const zoneMessages = ref(null)
let intervalleChat = null

const obtenirConversationId = () => {
  if (user.value?.id) return user.value.id
  if (typeof window === 'undefined') return null
  let id = localStorage.getItem('retrouva_support_id')
  if (!id) {
    id = 'anon-' + Math.random().toString(36).slice(2) + Date.now().toString(36)
    localStorage.setItem('retrouva_support_id', id)
  }
  return id
}

const scrollerEnBas = async () => {
  await nextTick()
  if (zoneMessages.value) zoneMessages.value.scrollTop = zoneMessages.value.scrollHeight
}

const chargerMessages = async () => {
  if (!configured || !supabase || !conversationId.value) return
  const { data } = await supabase
    .from('support_messages')
    .select('*')
    .eq('conversation_id', conversationId.value)
    .order('created_at', { ascending: true })
  const nouveauNombre = data?.length || 0
  const etaitEnBas = zoneMessages.value ? (zoneMessages.value.scrollTop + zoneMessages.value.clientHeight >= zoneMessages.value.scrollHeight - 40) : true
  messages.value = data || []
  if (nouveauNombre !== messages.value.length || etaitEnBas) scrollerEnBas()
}

const ouvrirChat = () => {
  ouvert.value = false
  chatOuvert.value = true
  conversationId.value = obtenirConversationId()
  chargerMessages()
  if (intervalleChat) clearInterval(intervalleChat)
  intervalleChat = setInterval(chargerMessages, 5000)
}
const fermerChat = () => {
  chatOuvert.value = false
  if (intervalleChat) clearInterval(intervalleChat)
}

const envoyerMessage = async () => {
  const contenu = nouveauMessage.value.trim()
  if (!contenu || !configured || !supabase || !conversationId.value) return
  envoiEnCours.value = true
  const { error } = await supabase.from('support_messages').insert({
    conversation_id: conversationId.value,
    auteur: 'utilisateur',
    nom_visiteur: profile.value?.nom_affiche || null,
    contenu
  })
  if (!error) nouveauMessage.value = ''
  envoiEnCours.value = false
  await chargerMessages()
}

onMounted(async () => {
  if (!configured || !supabase) return
  const { data } = await supabase.from('site_settings').select('valeur').eq('cle', 'whatsapp_support_numero').maybeSingle()
  if (data?.valeur) numeroWhatsapp.value = data.valeur
})
onBeforeUnmount(() => { if (intervalleChat) clearInterval(intervalleChat) })
</script>

<template>
  <div class="fixed z-[55] bottom-24 right-4 md:bottom-6 md:right-6 flex flex-col items-end gap-3">
    <!-- Options qui se déploient au-dessus du bouton principal -->
    <transition-group
      enter-active-class="transition duration-150 ease-out"
      enter-from-class="opacity-0 translate-y-2 scale-90"
      enter-to-class="opacity-100 translate-y-0 scale-100"
      leave-active-class="transition duration-100 ease-in"
      leave-to-class="opacity-0 translate-y-2 scale-90"
    >
      <a
        v-if="ouvert" key="whatsapp"
        :href="lienWhatsapp" target="_blank" rel="noopener"
        class="flex items-center gap-2.5 rounded-full bg-[#25D366] text-white shadow-floating pl-4 pr-5 py-3 text-sm font-semibold tap-target"
      >
        <IconTab name="whatsapp" class="h-5 w-5" /> WhatsApp
      </a>

      <button
        v-if="ouvert && scrolled" key="remonter" type="button"
        class="flex items-center gap-2.5 rounded-full bg-white dark:bg-forest-800 text-forest-700 dark:text-ivoire-100 shadow-floating pl-4 pr-5 py-3 text-sm font-semibold tap-target"
        @click="remonter"
      >
        <IconTab name="arrowUp" class="h-5 w-5" /> Remonter en haut
      </button>

      <button
        v-if="ouvert" key="chat" type="button"
        class="flex items-center gap-2.5 rounded-full bg-forest-800 text-white shadow-floating pl-4 pr-5 py-3 text-sm font-semibold tap-target"
        @click="ouvrirChat"
      >
        <IconTab name="chat" class="h-5 w-5" /> Discuter avec le support
      </button>
    </transition-group>

    <!-- Bouton principal -->
    <button
      type="button"
      class="flex h-14 w-14 items-center justify-center rounded-full bg-savane-500 text-white shadow-floating transition-transform duration-200 tap-target"
      :class="ouvert ? 'rotate-45' : ''"
      aria-label="Ouvrir les options d'aide"
      @click="ouvert = !ouvert"
    >
      <IconTab name="plus" class="h-6 w-6" />
    </button>
  </div>

  <!-- Fenêtre de chat support -->
  <transition
    enter-active-class="transition duration-200 ease-out"
    enter-from-class="opacity-0 translate-y-4"
    enter-to-class="opacity-100 translate-y-0"
    leave-active-class="transition duration-150 ease-in"
    leave-to-class="opacity-0 translate-y-4"
  >
    <div
      v-if="chatOuvert"
      class="fixed z-[56] inset-x-4 bottom-4 sm:inset-x-auto sm:bottom-6 sm:right-6 sm:w-96 flex flex-col rounded-2xl bg-white dark:bg-forest-900 shadow-floating overflow-hidden"
      style="max-height: min(75vh, 32rem);"
    >
      <div class="flex items-center justify-between gap-3 bg-forest-800 text-white px-4 py-3.5 shrink-0">
        <div class="flex items-center gap-2.5 min-w-0">
          <span class="flex h-9 w-9 shrink-0 items-center justify-center rounded-full bg-savane-500">
            <IconTab name="chat" class="h-4 w-4" />
          </span>
          <div class="min-w-0">
            <p class="font-display font-semibold text-sm truncate">Support technique RETROUVA</p>
            <p class="text-[11px] text-ivoire-100/70">Généralement une réponse sous peu</p>
          </div>
        </div>
        <button class="shrink-0 text-ivoire-100/70 hover:text-white" aria-label="Fermer" @click="fermerChat">
          <IconTab name="close" class="h-5 w-5" />
        </button>
      </div>

      <div ref="zoneMessages" class="flex-1 overflow-y-auto p-4 space-y-3 bg-forest-50/40 dark:bg-forest-950/40">
        <p v-if="!messages.length" class="text-sm text-forest-500 text-center py-6">
          Posez votre question, un membre de l'équipe RETROUVA vous répondra ici.
        </p>
        <div
          v-for="m in messages" :key="m.id"
          class="max-w-[85%] rounded-2xl px-3.5 py-2.5 text-sm"
          :class="m.auteur === 'admin'
            ? 'bg-white dark:bg-forest-800 text-forest-800 dark:text-ivoire-100 mr-auto rounded-bl-sm shadow-card'
            : 'bg-savane-500 text-white ml-auto rounded-br-sm'"
        >
          {{ m.contenu }}
        </div>
      </div>

      <form class="flex items-center gap-2 border-t border-forest-100 dark:border-forest-800 p-3 shrink-0" @submit.prevent="envoyerMessage">
        <input
          v-model="nouveauMessage" type="text" placeholder="Écrivez votre message…"
          class="input-field !py-2.5 flex-1"
        />
        <button type="submit" class="btn-accent !px-4 !py-2.5 shrink-0" :disabled="envoiEnCours || !nouveauMessage.trim()">
          <IconTab name="arrow" class="h-4 w-4 -rotate-90" />
        </button>
      </form>
    </div>
  </transition>
</template>
