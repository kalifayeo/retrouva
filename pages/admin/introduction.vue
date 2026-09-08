<script setup>
definePageMeta({ middleware: 'admin', layout: 'admin' })

const supabase = useSupabase()
const { user } = useAuth()
const { televerserAvecRetry } = useUploadImage()

const slides = ref([])
const loading = ref(true)
const saving = ref(false)
const editionId = ref(null)

// ---------------------------------------------------------------------
// VIDÉO DE PRÉSENTATION — affichée à la première connexion sur un
// appareil (avant ou après les diapositives ci-dessous), passable à
// tout moment. Réglage unique (une seule ligne en base).
// ---------------------------------------------------------------------
const videoConfig = reactive({ actif: false, titre: '', video_url: '', position: 'avant' })
const loadingVideo = ref(true)
const savingVideo = ref(false)
const succesVideo = ref(false)
const fichierVideoIntro = ref(null)
const televersementVideoIntro = ref(false)
const erreurVideoIntro = ref('')

const onFichierVideoIntro = (e) => { fichierVideoIntro.value = e.target.files?.[0] || null }

const televerserVideoIntro = async () => {
  if (!fichierVideoIntro.value) return
  erreurVideoIntro.value = ''
  televersementVideoIntro.value = true
  try {
    const path = `intro-video/${Date.now()}-${fichierVideoIntro.value.name}`
    const { error } = await televerserAvecRetry(supabase, 'site-media', path, fichierVideoIntro.value)
    if (error) throw error
    const { data } = supabase.storage.from('site-media').getPublicUrl(path)
    videoConfig.video_url = data.publicUrl
    fichierVideoIntro.value = null
    await enregistrerVideo()
  } catch (e) {
    const message = String(e.message || '')
    erreurVideoIntro.value = /50[0-9]/.test(message)
      ? "Échec de l'envoi (erreur serveur temporaire " + message + "). Réessayez dans un instant."
      : "Échec de l'envoi : " + message + " — vérifiez que le bucket 'site-media' existe et est public (voir README)."
  } finally {
    televersementVideoIntro.value = false
  }
}

const chargerVideo = async () => {
  loadingVideo.value = true
  const { data } = await supabase.from('intro_video_config').select('*').eq('id', 'principal').maybeSingle()
  if (data) Object.assign(videoConfig, data)
  loadingVideo.value = false
}

const enregistrerVideo = async () => {
  savingVideo.value = true
  succesVideo.value = false
  await supabase.from('intro_video_config').update({
    actif: videoConfig.actif,
    titre: videoConfig.titre || 'Découvrez RETROUVA en vidéo',
    video_url: videoConfig.video_url || null,
    position: videoConfig.position,
    updated_by: user.value.id,
    updated_at: new Date().toISOString()
  }).eq('id', 'principal')
  savingVideo.value = false
  succesVideo.value = true
  setTimeout(() => { succesVideo.value = false }, 3000)
}

const iconesDisponibles = ['pin', 'card', 'search', 'shield', 'check', 'handshake', 'bell', 'clock', 'chat', 'user', 'plus']

const vide = () => ({ titre: '', description: '', icone: 'card', ordre: (slides.value.length + 1) * 10, actif: true })
const form = reactive(vide())

const charger = async () => {
  loading.value = true
  const { data } = await supabase.from('onboarding_slides').select('*').order('ordre', { ascending: true })
  slides.value = data || []
  loading.value = false
}

const editer = (s) => { editionId.value = s.id; Object.assign(form, s) }
const nouveau = () => { editionId.value = null; Object.assign(form, vide()) }

const enregistrer = async () => {
  saving.value = true
  const payload = {
    titre: form.titre, description: form.description,
    icone: form.icone, ordre: form.ordre, actif: form.actif,
    created_by: user.value.id
  }
  if (editionId.value) await supabase.from('onboarding_slides').update(payload).eq('id', editionId.value)
  else await supabase.from('onboarding_slides').insert(payload)
  saving.value = false
  nouveau()
  await charger()
}

const supprimer = async (id) => {
  if (!confirm('Supprimer cette diapositive ?')) return
  await supabase.from('onboarding_slides').delete().eq('id', id)
  await charger()
}

const deplacer = async (index, direction) => {
  const cible = index + direction
  if (cible < 0 || cible >= slides.value.length) return
  const a = slides.value[index]
  const b = slides.value[cible]
  await Promise.all([
    supabase.from('onboarding_slides').update({ ordre: b.ordre }).eq('id', a.id),
    supabase.from('onboarding_slides').update({ ordre: a.ordre }).eq('id', b.id)
  ])
  await charger()
}

onMounted(() => { charger(); chargerVideo() })
</script>

<template>
  <div class="section py-8 md:py-12">
    <div class="container-app max-w-2xl">
      <h1 class="text-2xl font-bold mb-1">Introduction du site</h1>
      <p class="text-forest-700/70 mb-6">
        Vidéo et diapositives affichées automatiquement à la première connexion sur un appareil, pour
        présenter la plateforme.
      </p>

      <!-- VIDÉO DE PRÉSENTATION -->
      <h2 class="font-display font-bold text-lg mb-3">Vidéo de présentation</h2>
      <form class="card p-5 space-y-4 mb-10" @submit.prevent="enregistrerVideo">
        <p v-if="loadingVideo" class="text-sm text-forest-500">Chargement…</p>
        <template v-else>
          <label class="flex items-center gap-2 text-sm">
            <input v-model="videoConfig.actif" type="checkbox" class="h-4 w-4 rounded border-forest-200 text-savane-500" />
            Afficher une vidéo à la première connexion sur un appareil
          </label>
          <div>
            <label class="label-field">Titre affiché au-dessus de la vidéo</label>
            <input v-model="videoConfig.titre" class="input-field" placeholder="Découvrez RETROUVA en vidéo" />
          </div>
          <div>
            <label class="label-field">Lien de la vidéo</label>
            <input v-model="videoConfig.video_url" class="input-field" placeholder="https://... (YouTube, Vimeo, ou lien direct .mp4)" />
            <p class="text-xs text-forest-400 mt-1.5">Collez un lien YouTube/Vimeo, ou l'URL directe d'un fichier vidéo déjà hébergé ailleurs.</p>
          </div>
          <div class="rounded-xl border border-dashed border-forest-200 dark:border-forest-700 p-4">
            <label class="label-field">Ou téléversez une vidéo depuis votre ordinateur</label>
            <video v-if="videoConfig.video_url && !/youtu\.be|youtube\.com|vimeo\.com/.test(videoConfig.video_url)" :src="videoConfig.video_url" controls class="w-full rounded-lg max-h-48 mb-3"></video>
            <input type="file" accept="video/*" class="input-field" @change="onFichierVideoIntro" />
            <div class="flex items-center gap-3 mt-3">
              <button type="button" class="btn-outline text-sm" :disabled="!fichierVideoIntro || televersementVideoIntro" @click="televerserVideoIntro">
                {{ televersementVideoIntro ? 'Envoi en cours…' : 'Téléverser cette vidéo' }}
              </button>
              <span v-if="televersementVideoIntro" class="text-xs text-forest-400">Cela peut prendre un moment selon la taille du fichier…</span>
            </div>
            <p class="text-xs text-forest-400 mt-2">Préférez un fichier léger (idéalement moins de 30 Mo, format .mp4) pour un chargement rapide sur mobile.</p>
            <p v-if="erreurVideoIntro" class="text-sm text-red-600 mt-2">{{ erreurVideoIntro }}</p>
          </div>
          <div>
            <label class="label-field">Quand l'afficher</label>
            <select v-model="videoConfig.position" class="input-field">
              <option value="avant">Avant les diapositives d'introduction</option>
              <option value="apres">Après les diapositives d'introduction</option>
            </select>
          </div>
          <p v-if="succesVideo" class="text-xs font-semibold text-forest-600">✅ Réglages enregistrés.</p>
          <button type="submit" class="btn-primary" :disabled="savingVideo" :class="{ 'opacity-60': savingVideo }">
            {{ savingVideo ? 'Enregistrement…' : 'Enregistrer' }}
          </button>
        </template>
      </form>

      <!-- DIAPOSITIVES -->
      <h2 class="font-display font-bold text-lg mb-3">Diapositives</h2>

      <form class="card p-5 space-y-4 mb-8" @submit.prevent="enregistrer">
        <h2 class="font-display font-semibold">{{ editionId ? 'Modifier la diapositive' : 'Nouvelle diapositive' }}</h2>
        <div>
          <label class="label-field">Titre</label>
          <input v-model="form.titre" class="input-field" required />
        </div>
        <div>
          <label class="label-field">Description</label>
          <textarea v-model="form.description" rows="2" class="input-field resize-none"></textarea>
        </div>
        <div class="grid sm:grid-cols-2 gap-4">
          <div>
            <label class="label-field">Icône</label>
            <select v-model="form.icone" class="input-field">
              <option v-for="i in iconesDisponibles" :key="i" :value="i">{{ i }}</option>
            </select>
          </div>
          <div>
            <label class="label-field">Ordre d'affichage</label>
            <input v-model.number="form.ordre" type="number" class="input-field" />
          </div>
        </div>
        <label class="flex items-center gap-2 text-sm">
          <input v-model="form.actif" type="checkbox" class="h-4 w-4 rounded border-forest-200 text-savane-500" />
          Diapositive active
        </label>
        <div class="flex gap-3">
          <button type="submit" class="btn-primary" :disabled="saving" :class="{ 'opacity-60': saving }">
            {{ saving ? 'Enregistrement…' : (editionId ? 'Mettre à jour' : 'Ajouter') }}
          </button>
          <button v-if="editionId" type="button" class="btn-outline" @click="nouveau">Annuler</button>
        </div>
      </form>

      <p v-if="loading" class="text-sm text-forest-500">Chargement…</p>
      <div v-else class="space-y-3">
        <div v-for="(s, i) in slides" :key="s.id" class="card p-4 flex items-center gap-4">
          <span class="flex h-11 w-11 shrink-0 items-center justify-center rounded-2xl bg-savane-500 text-white">
            <IconTab :name="s.icone" class="h-5 w-5" />
          </span>
          <div class="flex-1 min-w-0">
            <p class="font-display font-semibold text-sm truncate">{{ s.titre }}</p>
            <p class="text-xs text-forest-400">{{ s.actif ? 'active' : 'inactive' }} · ordre {{ s.ordre }}</p>
          </div>
          <div class="flex items-center gap-1 shrink-0">
            <button class="p-1.5 text-forest-400 hover:text-forest-700" :disabled="i === 0" @click="deplacer(i, -1)" aria-label="Monter">
              <IconTab name="arrow" class="h-4 w-4 -rotate-90" />
            </button>
            <button class="p-1.5 text-forest-400 hover:text-forest-700" :disabled="i === slides.length - 1" @click="deplacer(i, 1)" aria-label="Descendre">
              <IconTab name="arrow" class="h-4 w-4 rotate-90" />
            </button>
            <button class="text-xs text-forest-600 font-semibold hover:underline ml-2" @click="editer(s)">Modifier</button>
            <button class="text-xs text-red-500 font-semibold hover:underline ml-2" @click="supprimer(s.id)">Supprimer</button>
          </div>
        </div>

        <p v-if="!slides.length" class="text-center py-10 text-forest-500">Aucune diapositive pour le moment.</p>
      </div>
    </div>
  </div>
</template>
