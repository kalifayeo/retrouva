<script setup>
definePageMeta({ middleware: 'auth' })

const { user } = useAuth()
const { objectTypes } = useObjectTypes()
const supabase = useSupabase()

const conversations = ref([])
const loading = ref(true)

const labelType = (id) => objectTypes.find(t => t.id === id)?.label || id

const charger = async () => {
  loading.value = true
  if (!supabase || !user.value) { loading.value = false; return }

  const { data, error } = await supabase
    .from('messages')
    .select(`
      id, match_id, contenu, lu, created_at, expediteur_id, destinataire_id,
      match:matches(
        id,
        lost_report:lost_reports(object_type_id),
        found_report:found_reports(ville, commune)
      )
    `)
    .or(`expediteur_id.eq.${user.value.id},destinataire_id.eq.${user.value.id}`)
    .order('created_at', { ascending: false })

  if (!error) {
    const vues = new Map()
    for (const m of data || []) {
      if (!vues.has(m.match_id)) vues.set(m.match_id, m)
    }
    conversations.value = Array.from(vues.values())
  }
  loading.value = false
}

onMounted(charger)
</script>

<template>
  <div class="section py-8 md:py-12">
    <div class="container-app max-w-xl">
      <h1 class="text-2xl font-bold mb-6">Messagerie</h1>

      <p v-if="loading" class="text-sm text-forest-500">Chargement…</p>

      <div v-else-if="conversations.length" class="card divide-y divide-forest-50 overflow-hidden">
        <NuxtLink
          v-for="c in conversations"
          :key="c.match_id"
          :to="`/messagerie/${c.match_id}`"
          class="w-full flex items-center gap-3 px-5 py-4 text-left tap-target"
        >
          <span class="flex h-11 w-11 shrink-0 items-center justify-center rounded-full bg-forest-50 text-forest-700">
            <IconTab name="chat" class="h-5 w-5" />
          </span>
          <span class="flex-1 min-w-0">
            <span class="flex items-center justify-between gap-2">
              <span class="font-display font-semibold text-sm truncate">
                {{ labelType(c.match?.lost_report?.object_type_id) }}
                <span v-if="c.match?.found_report?.ville" class="text-forest-400 font-normal">
                  — {{ c.match.found_report.commune ? `${c.match.found_report.commune}, ` : '' }}{{ c.match.found_report.ville }}
                </span>
              </span>
              <span class="text-xs text-forest-400 shrink-0">
                {{ new Date(c.created_at).toLocaleDateString('fr-FR') }}
              </span>
            </span>
            <span class="text-sm text-forest-500 truncate block">{{ c.contenu }}</span>
          </span>
          <span v-if="!c.lu && c.destinataire_id === user.id" class="h-2.5 w-2.5 rounded-full bg-savane-500 shrink-0"></span>
        </NuxtLink>
      </div>

      <div v-else class="text-center py-16 text-forest-500">
        Aucune conversation pour le moment. Elles apparaissent ici dès qu'une demande de
        vérification est envoyée sur une correspondance.
      </div>
    </div>
  </div>
</template>
