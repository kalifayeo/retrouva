<script setup>
definePageMeta({ middleware: 'admin', layout: 'admin' })

const supabase = useSupabase()
const { televerserAvecRetry } = useUploadImage()
const settings = ref({})
const loading = ref(true)
const saving = ref(false)
const saved = ref(false)
const fichierVideo = ref(null)
const uploadEnCours = ref(false)
const erreurUpload = ref('')

const fichierBackdrop = ref(null)
const uploadEnCoursBackdrop = ref(false)
const erreurBackdrop = ref('')
const backdropEnvoye = ref(false)

const champs = [
  { cle: 'hero_titre', label: "Titre principal (page d'accueil)" },
  { cle: 'hero_titre_accent', label: 'Titre — partie mise en avant (orange)' },
  { cle: 'hero_sous_titre', label: 'Sous-titre / paragraphe du hero' }
]

const charger = async () => {
  loading.value = true
  const { data } = await supabase.from('site_settings').select('cle, valeur')
  const map = {}
  for (const row of data || []) map[row.cle] = row.valeur
  settings.value = {
    hero_background_type: 'animation', hero_video_url: '', hero_backdrop_url: '', whatsapp_support_numero: '',
    maintenance_mode: 'off', maintenance_message: '',
    ...map
  }
  loading.value = false
}

const enregistrer = async () => {
  saving.value = true
  saved.value = false
  const toutesLesCles = [...champs.map(c => c.cle), 'hero_background_type', 'hero_video_url', 'hero_backdrop_url', 'whatsapp_support_numero', 'maintenance_mode', 'maintenance_message']
  for (const cle of toutesLesCles) {
    await supabase.from('site_settings').upsert({ cle, valeur: settings.value[cle] || '' })
  }
  saving.value = false
  saved.value = true
  setTimeout(() => (saved.value = false), 2500)
}

const maintenanceActive = computed({
  get: () => settings.value.maintenance_mode === 'on',
  set: (v) => { settings.value.maintenance_mode = v ? 'on' : 'off' }
})
const maintenanceEnCours = ref(false)
const erreurMaintenance = ref('')

// Bascule immédiate (sans attendre le bouton "Enregistrer" en bas de page) :
// le mode maintenance est une action sensible qu'on veut pouvoir activer/
// désactiver en un clic, notamment en urgence. On revient en arrière si
// l'enregistrement échoue, pour ne jamais afficher un interrupteur qui ment
// sur l'état réel du site.
const basculerMaintenance = async () => {
  erreurMaintenance.value = ''
  const nouvelEtat = !maintenanceActive.value
  maintenanceActive.value = nouvelEtat
  maintenanceEnCours.value = true
  try {
    const { error } = await supabase.from('site_settings').upsert({ cle: 'maintenance_mode', valeur: settings.value.maintenance_mode })
    if (error) throw error
  } catch (e) {
    maintenanceActive.value = !nouvelEtat // on annule le changement visuel
    erreurMaintenance.value = "Échec de l'enregistrement. Réessayez ou vérifiez votre connexion."
  } finally {
    maintenanceEnCours.value = false
  }
}

const onFichierVideo = (e) => { fichierVideo.value = e.target.files?.[0] || null }

const televerserVideo = async () => {
  if (!fichierVideo.value) return
  erreurUpload.value = ''
  uploadEnCours.value = true
  try {
    const path = `hero/${Date.now()}-${fichierVideo.value.name}`
    const { error } = await televerserAvecRetry(supabase, 'site-media', path, fichierVideo.value)
    if (error) throw error
    const { data } = supabase.storage.from('site-media').getPublicUrl(path)
    settings.value.hero_video_url = data.publicUrl
    settings.value.hero_background_type = 'video'
    await enregistrer()
  } catch (e) {
    erreurUpload.value = "Échec de l'envoi. Vérifiez que le bucket 'site-media' existe (voir README)."
  } finally {
    uploadEnCours.value = false
  }
}

const onFichierBackdrop = (e) => { fichierBackdrop.value = e.target.files?.[0] || null }

const televerserBackdrop = async () => {
  if (!fichierBackdrop.value) return
  erreurBackdrop.value = ''
  backdropEnvoye.value = false
  uploadEnCoursBackdrop.value = true
  try {
    const path = `hero-backdrop/${Date.now()}-${fichierBackdrop.value.name}`
    const { error } = await televerserAvecRetry(supabase, 'site-media', path, fichierBackdrop.value)
    if (error) throw error
    const { data } = supabase.storage.from('site-media').getPublicUrl(path)
    settings.value.hero_backdrop_url = data.publicUrl
    await enregistrer()
    fichierBackdrop.value = null
    backdropEnvoye.value = true
    setTimeout(() => (backdropEnvoye.value = false), 3000)
  } catch (e) {
    erreurBackdrop.value = "Échec de l'envoi. Vérifiez que le bucket 'site-media' existe et que ses politiques d'upload sont bien configurées (voir README, section stockage)."
  } finally {
    uploadEnCoursBackdrop.value = false
  }
}

const retirerBackdrop = async () => {
  settings.value.hero_backdrop_url = ''
  await enregistrer()
}

onMounted(charger)
</script>

<template>
  <div class="section py-8 md:py-12">
    <div class="container-app max-w-2xl">
      <h1 class="text-2xl font-bold mb-1">Contenu du site</h1>
      <p class="text-forest-700/70 mb-6">
        Modifiez les textes et le fond visuel de la page d'accueil. Les changements sont visibles
        immédiatement sur le site après enregistrement.
      </p>

      <p v-if="loading" class="text-sm text-forest-500">Chargement…</p>

      <form v-else class="space-y-8" @submit.prevent="enregistrer">
        <div class="space-y-5">
          <div v-for="c in champs" :key="c.cle">
            <label class="label-field">{{ c.label }}</label>
            <textarea v-model="settings[c.cle]" rows="2" class="input-field resize-none"></textarea>
          </div>
        </div>

        <div class="card p-5 space-y-4">
          <h2 class="font-display font-semibold">Fond visuel de l'accueil (à côté du logo)</h2>

          <div class="flex gap-3">
            <label class="flex-1 flex items-center gap-2 rounded-2xl border-2 px-4 py-3 cursor-pointer"
              :class="settings.hero_background_type === 'animation' ? 'border-savane-500 bg-savane-50' : 'border-forest-100'">
              <input v-model="settings.hero_background_type" type="radio" value="animation" class="text-savane-500" />
              <span class="text-sm font-medium">Animation (par défaut)</span>
            </label>
            <label class="flex-1 flex items-center gap-2 rounded-2xl border-2 px-4 py-3 cursor-pointer"
              :class="settings.hero_background_type === 'video' ? 'border-savane-500 bg-savane-50' : 'border-forest-100'">
              <input v-model="settings.hero_background_type" type="radio" value="video" class="text-savane-500" />
              <span class="text-sm font-medium">Vidéo</span>
            </label>
          </div>

          <div v-if="settings.hero_background_type === 'video'" class="space-y-3">
            <video v-if="settings.hero_video_url" :src="settings.hero_video_url" muted loop autoplay playsinline class="w-full rounded-xl max-h-40 object-cover"></video>
            <label class="label-field">Remplacer la vidéo (.mp4, courte, sans son)</label>
            <input type="file" accept="video/mp4" class="input-field" @change="onFichierVideo" />
            <button type="button" class="btn-outline text-sm" :disabled="!fichierVideo || uploadEnCours" @click="televerserVideo">
              {{ uploadEnCours ? 'Envoi en cours…' : 'Téléverser cette vidéo' }}
            </button>
            <p v-if="erreurUpload" class="text-sm text-red-600">{{ erreurUpload }}</p>
          </div>
        </div>

        <div class="card p-5 space-y-4">
          <h2 class="font-display font-semibold">Image de fond décorative (optionnel)</h2>
          <p class="text-sm text-forest-500">
            Une image ou un GIF affiché en fond sur toute la section d'accueil (texte compris),
            avec un léger dégradé pour garder le texte lisible.
          </p>
          <img v-if="settings.hero_backdrop_url" :src="settings.hero_backdrop_url" class="w-full h-32 object-cover rounded-xl" />
          <label class="label-field">Image ou GIF</label>
          <input type="file" accept="image/*,.gif" class="input-field" @change="onFichierBackdrop" />
          <div class="flex gap-3">
            <button type="button" class="btn-outline text-sm" :disabled="!fichierBackdrop || uploadEnCoursBackdrop" @click="televerserBackdrop">
              {{ uploadEnCoursBackdrop ? 'Envoi en cours…' : 'Téléverser' }}
            </button>
            <button v-if="settings.hero_backdrop_url" type="button" class="text-sm text-red-500 font-semibold" @click="retirerBackdrop">
              Retirer l'image de fond
            </button>
          </div>
          <p v-if="erreurBackdrop" class="text-sm text-red-600">{{ erreurBackdrop }}</p>
          <p v-if="backdropEnvoye" class="text-sm text-forest-600 flex items-center gap-1.5">
            <IconTab name="check" class="h-4 w-4" /> Image enregistrée et visible sur l'accueil.
          </p>
        </div>

        <div class="card p-5 space-y-4">
          <h2 class="font-display font-semibold">Contact &amp; support</h2>
          <div>
            <label class="label-field">Numéro WhatsApp du support</label>
            <input v-model="settings.whatsapp_support_numero" class="input-field" placeholder="225XXXXXXXXX (avec l'indicatif, sans le +)" />
            <p class="text-xs text-forest-400 mt-1.5">Utilisé par le bouton WhatsApp flottant, visible en bas à droite sur tout le site.</p>
          </div>
        </div>

        <div class="card p-5 space-y-4" :class="maintenanceActive ? 'border-savane-500 border-2' : ''">
          <div class="flex items-center justify-between gap-4">
            <div>
              <h2 class="font-display font-semibold">Mode maintenance</h2>
              <p class="text-sm text-forest-500 mt-1 max-w-md">
                Une fois activé, tout le site public redirige vers une page « Maintenance en
                cours ». L'administration reste accessible pour pouvoir le désactiver.
              </p>
            </div>
            <div class="shrink-0 flex flex-col items-end gap-1.5">
              <button
                type="button"
                class="relative inline-flex h-8 w-14 items-center rounded-full transition-colors disabled:opacity-60"
                :class="maintenanceActive ? 'bg-savane-500' : 'bg-forest-200'"
                :disabled="maintenanceEnCours"
                @click="basculerMaintenance"
                :aria-pressed="maintenanceActive"
                aria-label="Activer ou désactiver le mode maintenance"
              >
                <span
                  class="inline-block h-6 w-6 transform rounded-full bg-white shadow transition-transform"
                  :class="maintenanceActive ? 'translate-x-7' : 'translate-x-1'"
                ></span>
              </button>
              <span class="text-[11px] font-bold uppercase tracking-wide" :class="maintenanceActive ? 'text-savane-600' : 'text-forest-400'">
                {{ maintenanceEnCours ? 'Mise à jour…' : (maintenanceActive ? 'Activé' : 'Désactivé') }}
              </span>
            </div>
          </div>
          <p v-if="maintenanceActive" class="text-sm font-semibold text-savane-700 flex items-center gap-1.5">
            <IconTab name="bell" class="h-4 w-4" /> Le site public est actuellement en maintenance.
          </p>
          <p v-if="erreurMaintenance" class="text-sm text-red-600 flex items-center gap-1.5">
            <IconTab name="bell" class="h-4 w-4" /> {{ erreurMaintenance }}
          </p>
          <div>
            <label class="label-field">Message affiché sur la page de maintenance (optionnel)</label>
            <textarea v-model="settings.maintenance_message" rows="2" class="input-field resize-none" placeholder="Ex. : Retour prévu à 18h."></textarea>
          </div>
        </div>

        <div class="flex items-center gap-3">
          <button type="submit" class="btn-primary" :disabled="saving" :class="{ 'opacity-60': saving }">
            {{ saving ? 'Enregistrement…' : 'Enregistrer' }}
          </button>
          <span v-if="saved" class="text-sm text-forest-600 flex items-center gap-1">
            <IconTab name="check" class="h-4 w-4" /> Enregistré
          </span>
        </div>
      </form>
    </div>
  </div>
</template>
