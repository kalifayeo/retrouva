<script setup>
definePageMeta({ middleware: 'admin', layout: 'admin' })

const supabase = useSupabase()
const { user } = useAuth()
const { televerserAvecRetry } = useUploadImage()

const bannieres = ref([])
const loading = ref(true)
const saving = ref(false)
const editionId = ref(null)
const erreur = ref('')

const vide = () => ({ titre: '', texte: '', lien_url: '', position: 'accueil', actif: true, image_url: '', nom_entreprise: '', contact_entreprise: '' })
const form = reactive(vide())
const fichier = ref(null)

const charger = async () => {
  loading.value = true
  const { data } = await supabase.from('banners').select('*').order('created_at', { ascending: false })
  bannieres.value = data || []
  loading.value = false
}

const editer = (b) => {
  editionId.value = b.id
  Object.assign(form, b)
}

const nouvelleAnnonce = () => {
  editionId.value = null
  Object.assign(form, vide())
  fichier.value = null
  erreur.value = ''
}

const onFichier = (e) => { fichier.value = e.target.files?.[0] || null }

const enregistrer = async () => {
  saving.value = true
  erreur.value = ''

  let image_url = form.image_url
  if (fichier.value) {
    const path = `banners/${Date.now()}-${fichier.value.name}`
    const { error: uploadError } = await televerserAvecRetry(supabase, 'site-media', path, fichier.value)
    if (uploadError) {
      const message = String(uploadError.message || '')
      erreur.value = /50[0-9]/.test(message)
        ? "Échec de l'envoi de l'image (erreur serveur temporaire " + message + "). Réessayez dans un instant, ou avec une image plus légère."
        : "Échec de l'envoi de l'image : " + message +
          " — vérifiez que le bucket 'site-media' existe et est public (voir README)."
      saving.value = false
      return
    }
    image_url = supabase.storage.from('site-media').getPublicUrl(path).data.publicUrl
  }

  const payload = {
    titre: form.titre,
    texte: form.texte,
    lien_url: form.lien_url,
    position: form.position,
    actif: form.actif,
    image_url,
    nom_entreprise: form.nom_entreprise || null,
    contact_entreprise: form.contact_entreprise || null,
    created_by: user.value.id
  }

  if (editionId.value) {
    await supabase.from('banners').update(payload).eq('id', editionId.value)
  } else {
    await supabase.from('banners').insert(payload)
  }

  saving.value = false
  nouvelleAnnonce()
  await charger()
}

const supprimer = async (id) => {
  await supabase.from('banners').delete().eq('id', id)
  await charger()
}

onMounted(charger)
</script>

<template>
  <div class="section py-8 md:py-12">
    <div class="container-app max-w-3xl">
      <h1 class="text-2xl font-bold mb-1">Bannières &amp; publicités</h1>
      <p class="text-forest-700/70 mb-6">Publicités et annonces affichées sur le site — internes ou pour le compte d'une entreprise partenaire.</p>

      <form class="card p-5 space-y-4 mb-8" @submit.prevent="enregistrer">
        <h2 class="font-display font-semibold">{{ editionId ? 'Modifier la bannière' : 'Nouvelle bannière' }}</h2>
        <div>
          <label class="label-field">Titre</label>
          <input v-model="form.titre" class="input-field" required />
        </div>
        <div>
          <label class="label-field">Texte</label>
          <textarea v-model="form.texte" rows="2" class="input-field resize-none"></textarea>
        </div>
        <div class="grid sm:grid-cols-2 gap-4 pt-1 border-t border-forest-50">
          <div>
            <label class="label-field">Entreprise annonceur <span class="font-normal normal-case text-forest-400">(si publicité payante)</span></label>
            <input v-model="form.nom_entreprise" class="input-field" placeholder="Ex. Orange CI" />
          </div>
          <div>
            <label class="label-field">Contact de l'entreprise</label>
            <input v-model="form.contact_entreprise" class="input-field" placeholder="E-mail ou téléphone" />
          </div>
        </div>
        <div class="grid sm:grid-cols-2 gap-4">
          <div>
            <label class="label-field">Lien (au clic)</label>
            <input v-model="form.lien_url" class="input-field" placeholder="https://…" />
          </div>
          <div>
            <label class="label-field">Position</label>
            <select v-model="form.position" class="input-field">
              <option value="accueil">Accueil</option>
              <option value="resultats">Résultats</option>
              <option value="accueil_pub">Accueil — espace publicitaire</option>
              <option value="toutes_pages">Toutes les pages</option>
            </select>
          </div>
        </div>
        <div>
          <label class="label-field">Image</label>
          <input type="file" accept="image/*" class="input-field" @change="onFichier" />
        </div>
        <label class="flex items-center gap-2 text-sm">
          <input v-model="form.actif" type="checkbox" class="h-4 w-4 rounded border-forest-200 text-savane-500" />
          Bannière active
        </label>
        <p v-if="erreur" class="text-sm text-red-600">{{ erreur }}</p>
        <div class="flex gap-3">
          <button type="submit" class="btn-primary" :disabled="saving" :class="{ 'opacity-60': saving }">
            {{ saving ? 'Enregistrement…' : (editionId ? 'Mettre à jour' : 'Publier') }}
          </button>
          <button v-if="editionId" type="button" class="btn-outline" @click="nouvelleAnnonce">Annuler</button>
        </div>
      </form>

      <p v-if="loading" class="text-sm text-forest-500">Chargement…</p>
      <div v-else class="space-y-3">
        <div v-for="b in bannieres" :key="b.id" class="card p-4 flex items-center gap-4">
          <img v-if="b.image_url" :src="b.image_url" class="h-14 w-14 rounded-xl object-cover shrink-0" />
          <div class="flex-1 min-w-0">
            <p class="font-display font-semibold text-sm truncate">{{ b.titre }}</p>
            <p class="text-xs text-forest-400">
              {{ b.position }} · {{ b.actif ? 'active' : 'inactive' }}<span v-if="b.nom_entreprise"> · Pub {{ b.nom_entreprise }}</span>
            </p>
          </div>
          <button class="text-sm text-forest-600 font-semibold" @click="editer(b)">Modifier</button>
          <button class="text-sm text-red-500 font-semibold" @click="supprimer(b.id)">Supprimer</button>
        </div>
        <p v-if="!bannieres.length" class="text-center py-10 text-forest-500">Aucune bannière pour le moment.</p>
      </div>
    </div>
  </div>
</template>
