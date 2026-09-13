<script setup>
const route = useRoute()
const { objectTypes, villes, communesAbidjan } = useObjectTypes()
const { user } = useAuth()
const supabase = useSupabase()

const step = ref(1)
const totalSteps = 3

const form = reactive({
  type: route.query.type || '',
  description: '',
  ville: '',
  commune: '',
  date: '',
  consentement: false
})

const submitted = ref(false)
const submitting = ref(false)
const submitError = ref('')
const photoName = ref('')
const photoFile = ref(null)

const onPhoto = (e) => {
  const file = e.target.files?.[0]
  photoFile.value = file || null
  photoName.value = file ? file.name : ''
}

const conseils = [
  { titre: 'Décrivez sans trop en dire', texte: "Couleur, marque, lieu précis : suffisant pour permettre une correspondance, sans exposer d'informations sensibles.", icon: 'shield' },
  { titre: 'Gardez l\'objet en sécurité', texte: "Conservez-le chez vous ou déposez-le dans un point relais RETROUVA en attendant la mise en relation.", icon: 'pin' },
  { titre: 'Ne remettez qu\'après vérification', texte: "Le propriétaire doit confirmer des détails précis avant toute remise.", icon: 'check' }
]

const canNext = computed(() => {
  if (step.value === 1) return !!form.type
  if (step.value === 2) return !!form.ville && !!form.date
  return true
})

const next = () => { if (step.value < totalSteps) step.value++ }
const back = () => { if (step.value > 1) step.value-- }

const submit = async () => {
  if (!user.value) {
    return navigateTo(`/connexion?next=/trouve`)
  }
  if (!supabase) {
    submitError.value = "Supabase n'est pas configuré (fichier .env manquant). Voir le README."
    return
  }
  submitting.value = true
  submitError.value = ''

  // Évite les doublons créés par erreur (double clic, tests répétés…)
  const { data: existantes } = await supabase
    .from('found_reports')
    .select('id')
    .eq('user_id', user.value.id)
    .eq('object_type_id', form.type)
    .eq('ville', form.ville)
    .eq('date_trouvaille', form.date)
    .eq('statut', 'active')

  if (existantes?.length) {
    const continuer = confirm(
      'Vous avez déjà une déclaration active pour ce type d\'objet, cette ville et cette date. ' +
      'Voulez-vous quand même en créer une nouvelle ?'
    )
    if (!continuer) {
      submitting.value = false
      return
    }
  }

  let photo_url = null
  if (photoFile.value) {
    const path = `${user.value.id}/${Date.now()}-${photoFile.value.name}`
    const { error: uploadError } = await supabase
      .storage.from('objets-trouves')
      .upload(path, photoFile.value)
    if (!uploadError) {
      const { data } = supabase.storage.from('objets-trouves').getPublicUrl(path)
      photo_url = data.publicUrl
    }
    // En cas d'erreur d'upload (ex. bucket non créé), on continue sans photo
    // plutôt que de bloquer la déclaration.
  }

  const { error } = await supabase.from('found_reports').insert({
    user_id: user.value.id,
    object_type_id: form.type,
    description: form.description,
    ville: form.ville,
    commune: form.commune || null,
    date_trouvaille: form.date,
    photo_url,
    consentement_publication: form.consentement
  })

  submitting.value = false
  if (error) {
    submitError.value = "Une erreur est survenue lors de l'enregistrement. Réessayez."
    return
  }
  submitted.value = true
}
</script>

<template>
  <div class="section py-8 md:py-12">
    <div class="container-app max-w-5xl">
    <div class="grid lg:grid-cols-5 gap-8 lg:gap-12 items-start">
    <div class="lg:col-span-3">
      <div class="flex items-center gap-2 mb-6">
        <span v-for="i in totalSteps" :key="i" class="h-1.5 flex-1 rounded-full" :class="i <= step ? 'bg-forest-800' : 'bg-forest-50'"></span>
      </div>

      <div v-if="!submitted">
        <h1 class="text-2xl font-bold mb-1">J'ai trouvé un objet</h1>
        <p class="text-forest-700/70 text-sm mb-8">Étape {{ step }} sur {{ totalSteps }} — merci pour votre geste&nbsp;!</p>

        <div v-if="step === 1">
          <label class="label-field">Quel type d'objet avez-vous trouvé&nbsp;?</label>
          <div class="grid grid-cols-3 gap-3">
            <ObjectTypeCard
              v-for="t in objectTypes"
              :key="t.id"
              :label="t.label"
              :icon="t.icon"
              :image="t.image"
              :selected="form.type === t.id"
              @select="form.type = t.id"
            />
          </div>
        </div>

        <div v-else-if="step === 2" class="space-y-5">
          <div>
            <label class="label-field">Ville où l'objet a été trouvé</label>
            <select v-model="form.ville" class="input-field">
              <option value="" disabled>Sélectionnez une ville</option>
              <option v-for="v in villes" :key="v" :value="v">{{ v }}</option>
            </select>
          </div>
          <div v-if="form.ville === 'Abidjan'">
            <label class="label-field">Commune</label>
            <select v-model="form.commune" class="input-field">
              <option value="" disabled>Sélectionnez une commune</option>
              <option v-for="c in communesAbidjan" :key="c" :value="c">{{ c }}</option>
            </select>
          </div>
          <div>
            <label class="label-field">Date de la découverte</label>
            <input v-model="form.date" type="date" class="input-field" />
          </div>
          <div>
            <label class="label-field">Description générale (sans révéler d'informations sensibles)</label>
            <textarea
              v-model="form.description"
              rows="3"
              placeholder="Ex : portefeuille en cuir marron, trouvé près du marché…"
              class="input-field resize-none"
            ></textarea>
          </div>
          <div>
            <label class="label-field">Photo (facultatif — les infos sensibles seront automatiquement masquées)</label>
            <label class="flex items-center justify-center gap-2 rounded-2xl border-2 border-dashed border-forest-100 py-6 text-sm text-forest-500 cursor-pointer hover:border-savane-300 tap-target">
              <IconTab name="plus" class="h-5 w-5" />
              {{ photoName || 'Ajouter une photo' }}
              <input type="file" accept="image/*" capture="environment" class="hidden" @change="onPhoto" />
            </label>
          </div>
        </div>

        <div v-else class="space-y-5">
          <div class="rounded-2xl bg-savane-50 p-4 flex gap-3">
            <IconTab name="shield" class="h-5 w-5 text-savane-600 shrink-0 mt-0.5" />
            <p class="text-sm text-savane-800">
              Les numéros complets (carte, document) ne seront jamais publiés. Seul le propriétaire
              vérifié pourra confirmer ces détails avec vous, en messagerie sécurisée.
            </p>
          </div>
          <label class="flex items-start gap-3 text-sm text-forest-700 tap-target">
            <input v-model="form.consentement" type="checkbox" class="mt-1 h-4 w-4 rounded border-forest-200 text-savane-500 focus:ring-savane-300" />
            Je confirme que les informations fournies sont exactes et j'accepte que ma déclaration
            soit publiée de façon anonymisée.
          </label>
        </div>

        <div class="flex gap-3 mt-8">
          <button v-if="step > 1" class="btn-outline flex-1" @click="back">Retour</button>
          <button v-if="step < totalSteps" class="btn-primary flex-1" :disabled="!canNext" :class="{ 'opacity-40': !canNext }" @click="next">
            Continuer
          </button>
          <button v-else class="btn-accent flex-1" :disabled="!form.consentement || submitting" :class="{ 'opacity-40': !form.consentement || submitting }" @click="submit">
            {{ submitting ? 'Publication…' : 'Publier la déclaration' }}
          </button>
        </div>
        <p v-if="submitError" class="text-sm text-red-600 mt-3">{{ submitError }}</p>
      </div>

      <div v-else class="text-center py-10">
        <span class="mx-auto flex h-16 w-16 items-center justify-center rounded-full bg-savane-50 text-savane-600 mb-5">
          <IconTab name="check" class="h-7 w-7" />
        </span>
        <h2 class="text-xl font-bold mb-2">Merci pour votre honnêteté&nbsp;!</h2>
        <p class="text-forest-700/70 mb-8 max-w-sm mx-auto">
          Votre déclaration est publiée de façon sécurisée. Nous vous mettrons en relation dès
          qu'un propriétaire vérifié se manifeste.
        </p>
        <NuxtLink to="/mes-objets-trouves" class="btn-primary">Voir mes déclarations</NuxtLink>
      </div>
    </div>

    <!-- Colonne droite : parcours + conseils -->
    <div class="lg:col-span-2 space-y-5">
      <div class="card p-5">
        <p class="text-[11px] font-bold uppercase tracking-widest text-forest-400 mb-4">Ce qui va se passer</p>
        <ol class="space-y-4">
          <li class="flex items-start gap-3">
            <span class="flex h-6 w-6 shrink-0 items-center justify-center rounded-full bg-forest-800 text-white text-xs font-bold">1</span>
            <div>
              <p class="text-sm font-semibold text-forest-800">🟢 Objet déclaré</p>
              <p class="text-xs text-forest-500 mt-0.5">Votre déclaration est active et visible dans la recherche.</p>
            </div>
          </li>
          <li class="flex items-start gap-3">
            <span class="flex h-6 w-6 shrink-0 items-center justify-center rounded-full bg-forest-100 text-forest-600 text-xs font-bold">2</span>
            <div>
              <p class="text-sm font-semibold text-forest-500">🔎 Recherche du propriétaire</p>
              <p class="text-xs text-forest-400 mt-0.5">RETROUVA compare votre déclaration aux objets perdus.</p>
            </div>
          </li>
          <li class="flex items-start gap-3">
            <span class="flex h-6 w-6 shrink-0 items-center justify-center rounded-full bg-forest-100 text-forest-600 text-xs font-bold">3</span>
            <div>
              <p class="text-sm font-semibold text-forest-500">🔐 Vérification</p>
              <p class="text-xs text-forest-400 mt-0.5">Le demandeur confirme des détails que lui seul peut connaître.</p>
            </div>
          </li>
          <li class="flex items-start gap-3">
            <span class="flex h-6 w-6 shrink-0 items-center justify-center rounded-full bg-forest-100 text-forest-600 text-xs font-bold">4</span>
            <div>
              <p class="text-sm font-semibold text-forest-500">📦 Objet remis</p>
              <p class="text-xs text-forest-400 mt-0.5">Mise en relation sécurisée, puis remise organisée avec vous.</p>
            </div>
          </li>
        </ol>
      </div>

      <div v-for="c in conseils" :key="c.titre" class="card p-5 flex gap-3">
        <span class="flex h-9 w-9 items-center justify-center rounded-full bg-savane-50 text-savane-600 shrink-0">
          <IconTab :name="c.icon" class="h-4 w-4" />
        </span>
        <div>
          <p class="text-sm font-semibold text-forest-800">{{ c.titre }}</p>
          <p class="text-xs text-forest-500 mt-0.5 leading-relaxed">{{ c.texte }}</p>
        </div>
      </div>
    </div>
    </div>
    </div>
  </div>
</template>
