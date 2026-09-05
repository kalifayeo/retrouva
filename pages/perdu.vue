<script setup>
const route = useRoute()
const { objectTypes, villes, communesAbidjan } = useObjectTypes()
const { user } = useAuth()
const supabase = useSupabase()

const conseils = [
  { titre: 'Soyez précis mais prudent', texte: "Indiquez couleur, marque ou signe distinctif, sans donner de numéro complet (CNI, téléphone…).", icon: 'shield' },
  { titre: 'La date compte', texte: "Plus la date est précise, plus notre moteur affine le calcul de correspondance.", icon: 'clock' },
  { titre: 'Vous serez averti', texte: "Dès qu'une correspondance sérieuse est détectée, une notification vous est envoyée.", icon: 'bell' }
]

const { questionsPour } = useVerificationCriteres()

const step = ref(1)
const totalSteps = 4

const form = reactive({
  type: route.query.type || '',
  description: '',
  ville: '',
  commune: '',
  date: '',
  telephone: ''
})

const criteresValeurs = reactive({})

const questionsVerif = computed(() => form.type ? questionsPour(form.type) : [])

const submitted = ref(false)
const submitting = ref(false)
const submitError = ref('')

const canNext = computed(() => {
  if (step.value === 1) return !!form.type
  if (step.value === 2) return !!form.ville && !!form.date
  return true
})

const next = () => { if (step.value < totalSteps) step.value++ }
const back = () => { if (step.value > 1) step.value-- }

const submit = async () => {
  if (!user.value) {
    return navigateTo(`/connexion?next=/perdu`)
  }
  if (!supabase) {
    submitError.value = "Supabase n'est pas configuré (fichier .env manquant). Voir le README."
    return
  }
  submitting.value = true
  submitError.value = ''

  // Évite les doublons créés par erreur (double clic, tests répétés…) :
  // on prévient si une déclaration très similaire existe déjà et est active.
  const { data: existantes } = await supabase
    .from('lost_reports')
    .select('id')
    .eq('user_id', user.value.id)
    .eq('object_type_id', form.type)
    .eq('ville', form.ville)
    .eq('date_perte', form.date)
    .in('statut', ['active', 'correspondance'])

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

  const criteresRenseignes = questionsVerif.value
    .filter(q => criteresValeurs[q.key]?.trim())
    .map(q => ({ label: q.label, valeur: criteresValeurs[q.key].trim() }))

  const { error } = await supabase.from('lost_reports').insert({
    user_id: user.value.id,
    object_type_id: form.type,
    description: form.description,
    ville: form.ville,
    commune: form.commune || null,
    date_perte: form.date,
    criteres_verification: criteresRenseignes.length ? criteresRenseignes : null
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
        <span v-for="i in totalSteps" :key="i" class="h-1.5 flex-1 rounded-full" :class="i <= step ? 'bg-savane-500' : 'bg-forest-50'"></span>
      </div>

      <div v-if="!submitted">
        <h1 class="text-2xl font-bold mb-1">J'ai perdu un objet</h1>
        <p class="text-forest-700/70 text-sm mb-8">Étape {{ step }} sur {{ totalSteps }}</p>

        <!-- Étape 1 : type d'objet -->
        <div v-if="step === 1">
          <label class="label-field">Quel type d'objet avez-vous perdu&nbsp;?</label>
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

        <!-- Étape 2 : lieu et date -->
        <div v-else-if="step === 2" class="space-y-5">
          <div>
            <label class="label-field">Ville</label>
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
            <label class="label-field">Date approximative de la perte</label>
            <input v-model="form.date" type="date" class="input-field" />
          </div>
          <div>
            <label class="label-field">Description (facultatif, sans informations sensibles)</label>
            <textarea
              v-model="form.description"
              rows="3"
              placeholder="Couleur, marque, signe distinctif…"
              class="input-field resize-none"
            ></textarea>
          </div>
        </div>

        <!-- Étape 3 : éléments de vérification privés -->
        <div v-else-if="step === 3" class="space-y-5">
          <div class="rounded-2xl bg-forest-50 p-4 flex gap-3">
            <IconTab name="shield" class="h-5 w-5 text-forest-600 shrink-0 mt-0.5" />
            <p class="text-sm text-forest-700">
              Ces informations restent <strong>privées</strong>. Elles ne sont jamais publiées et ne
              servent qu'à confirmer que vous êtes bien le propriétaire, le jour où une
              correspondance est trouvée. Plus vous en renseignez, plus la vérification sera rapide.
            </p>
          </div>
          <div v-for="q in questionsVerif" :key="q.key">
            <label class="label-field">{{ q.label }} <span class="text-forest-300 font-normal">(facultatif)</span></label>
            <input v-model="criteresValeurs[q.key]" type="text" :placeholder="q.placeholder" class="input-field" />
          </div>
        </div>

        <!-- Étape 4 : récapitulatif -->
        <div v-else class="space-y-5">
          <div class="rounded-2xl bg-forest-50 p-4 flex gap-3">
            <IconTab name="shield" class="h-5 w-5 text-forest-600 shrink-0 mt-0.5" />
            <p class="text-sm text-forest-700">
              Vous serez notifié dès qu'une correspondance sérieuse est identifiée.
              Aucune information sensible n'est publiée.
            </p>
          </div>
          <div class="card p-4 text-sm space-y-1.5">
            <p><span class="text-forest-400">Type :</span> {{ objectTypes.find(t => t.id === form.type)?.label }}</p>
            <p><span class="text-forest-400">Lieu :</span> {{ form.commune ? `${form.commune}, ` : '' }}{{ form.ville }}</p>
            <p><span class="text-forest-400">Date :</span> {{ form.date }}</p>
            <p>
              <span class="text-forest-400">Éléments de vérification :</span>
              {{ questionsVerif.filter(q => criteresValeurs[q.key]?.trim()).length }} renseigné(s)
            </p>
          </div>
        </div>

        <div class="flex gap-3 mt-8">
          <button v-if="step > 1" class="btn-outline flex-1" @click="back">Retour</button>
          <button v-if="step < totalSteps" class="btn-primary flex-1" :disabled="!canNext" :class="{ 'opacity-40': !canNext }" @click="next">
            Continuer
          </button>
          <button v-else class="btn-accent flex-1" :disabled="submitting" :class="{ 'opacity-40': submitting }" @click="submit">
            {{ submitting ? 'Enregistrement…' : 'Lancer la recherche' }}
          </button>
        </div>
        <p v-if="submitError" class="text-sm text-red-600 mt-3">{{ submitError }}</p>
      </div>

      <!-- Confirmation -->
      <div v-else class="text-center py-10">
        <span class="mx-auto flex h-16 w-16 items-center justify-center rounded-full bg-forest-50 text-forest-700 mb-5">
          <IconTab name="check" class="h-7 w-7" />
        </span>
        <h2 class="text-xl font-bold mb-2">Recherche lancée</h2>
        <p class="text-forest-700/70 mb-8 max-w-sm mx-auto">
          Nous comparons votre déclaration aux objets trouvés. Vous serez notifié dès qu'une
          correspondance sérieuse est identifiée.
        </p>
        <NuxtLink to="/resultats" class="btn-primary">Voir les résultats</NuxtLink>
      </div>
    </div>

    <!-- Colonne droite : parcours + conseils -->
    <div class="lg:col-span-2 space-y-5">
      <div class="card p-5">
        <p class="text-[11px] font-bold uppercase tracking-widest text-forest-400 mb-4">Le parcours de votre objet</p>
        <ol class="space-y-4">
          <li class="flex items-start gap-3">
            <span class="flex h-6 w-6 shrink-0 items-center justify-center rounded-full bg-savane-500 text-white text-xs font-bold">1</span>
            <div>
              <p class="text-sm font-semibold text-forest-800">🔎 Recherche en cours</p>
              <p class="text-xs text-forest-500 mt-0.5">RETROUVA compare votre déclaration aux objets trouvés.</p>
            </div>
          </li>
          <li class="flex items-start gap-3">
            <span class="flex h-6 w-6 shrink-0 items-center justify-center rounded-full bg-forest-100 text-forest-600 text-xs font-bold">2</span>
            <div>
              <p class="text-sm font-semibold text-forest-500">🎯 Correspondance potentielle</p>
              <p class="text-xs text-forest-400 mt-0.5">Une piste sérieuse est détectée et vous êtes notifié.</p>
            </div>
          </li>
          <li class="flex items-start gap-3">
            <span class="flex h-6 w-6 shrink-0 items-center justify-center rounded-full bg-forest-100 text-forest-600 text-xs font-bold">3</span>
            <div>
              <p class="text-sm font-semibold text-forest-500">🔐 Vérification</p>
              <p class="text-xs text-forest-400 mt-0.5">Vous confirmez des détails que seul vous pouvez connaître.</p>
            </div>
          </li>
          <li class="flex items-start gap-3">
            <span class="flex h-6 w-6 shrink-0 items-center justify-center rounded-full bg-forest-100 text-forest-600 text-xs font-bold">4</span>
            <div>
              <p class="text-sm font-semibold text-forest-500">✅ Récupération</p>
              <p class="text-xs text-forest-400 mt-0.5">Mise en relation sécurisée, puis remise de l'objet.</p>
            </div>
          </li>
        </ol>
      </div>

      <div v-for="c in conseils" :key="c.titre" class="card p-5 flex gap-3">
        <span class="flex h-9 w-9 items-center justify-center rounded-full bg-forest-50 text-forest-600 shrink-0">
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
