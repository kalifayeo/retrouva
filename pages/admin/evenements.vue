<script setup>
definePageMeta({ middleware: 'admin', layout: 'admin' })

const supabase = useSupabase()
const { user } = useAuth()

const evenements = ref([])
const loading = ref(true)
const saving = ref(false)
const editionId = ref(null)

const vide = () => ({ titre: '', description: '', lieu: '', date_evenement: '', actif: true })
const form = reactive(vide())

const charger = async () => {
  loading.value = true
  const { data } = await supabase.from('events').select('*').order('date_evenement', { ascending: true })
  evenements.value = data || []
  loading.value = false
}

const editer = (e) => { editionId.value = e.id; Object.assign(form, e) }
const nouveau = () => { editionId.value = null; Object.assign(form, vide()) }

const enregistrer = async () => {
  saving.value = true
  const payload = { ...form, created_by: user.value.id }
  if (editionId.value) await supabase.from('events').update(payload).eq('id', editionId.value)
  else await supabase.from('events').insert(payload)
  saving.value = false
  nouveau()
  await charger()
}

const supprimer = async (id) => { await supabase.from('events').delete().eq('id', id); await charger() }

onMounted(charger)
</script>

<template>
  <div class="section py-8 md:py-12">
    <div class="container-app max-w-3xl">
      <h1 class="text-2xl font-bold mb-1">Événements</h1>
      <p class="text-forest-700/70 mb-6">Journées de restitution, campagnes de sensibilisation, etc.</p>

      <form class="card p-5 space-y-4 mb-8" @submit.prevent="enregistrer">
        <h2 class="font-display font-semibold">{{ editionId ? "Modifier l'événement" : 'Nouvel événement' }}</h2>
        <div>
          <label class="label-field">Titre</label>
          <input v-model="form.titre" class="input-field" required />
        </div>
        <div>
          <label class="label-field">Description</label>
          <textarea v-model="form.description" rows="3" class="input-field resize-none"></textarea>
        </div>
        <div class="grid sm:grid-cols-2 gap-4">
          <div>
            <label class="label-field">Lieu</label>
            <input v-model="form.lieu" class="input-field" />
          </div>
          <div>
            <label class="label-field">Date et heure</label>
            <input v-model="form.date_evenement" type="datetime-local" class="input-field" required />
          </div>
        </div>
        <label class="flex items-center gap-2 text-sm">
          <input v-model="form.actif" type="checkbox" class="h-4 w-4 rounded border-forest-200 text-savane-500" />
          Événement publié
        </label>
        <div class="flex gap-3">
          <button type="submit" class="btn-primary" :disabled="saving" :class="{ 'opacity-60': saving }">
            {{ saving ? 'Enregistrement…' : (editionId ? 'Mettre à jour' : 'Publier') }}
          </button>
          <button v-if="editionId" type="button" class="btn-outline" @click="nouveau">Annuler</button>
        </div>
      </form>

      <p v-if="loading" class="text-sm text-forest-500">Chargement…</p>
      <div v-else class="space-y-3">
        <div v-for="e in evenements" :key="e.id" class="card p-4 flex items-center gap-4">
          <span class="flex h-11 w-11 shrink-0 items-center justify-center rounded-full bg-forest-50 text-forest-700">
            <IconTab name="clock" class="h-5 w-5" />
          </span>
          <div class="flex-1 min-w-0">
            <p class="font-display font-semibold text-sm truncate">{{ e.titre }}</p>
            <p class="text-xs text-forest-400">
              {{ e.lieu ? `${e.lieu} · ` : '' }}{{ new Date(e.date_evenement).toLocaleString('fr-FR') }}
              · {{ e.actif ? 'publié' : 'brouillon' }}
            </p>
          </div>
          <button class="text-sm text-forest-600 font-semibold" @click="editer(e)">Modifier</button>
          <button class="text-sm text-red-500 font-semibold" @click="supprimer(e.id)">Supprimer</button>
        </div>
        <p v-if="!evenements.length" class="text-center py-10 text-forest-500">Aucun événement pour le moment.</p>
      </div>
    </div>
  </div>
</template>
