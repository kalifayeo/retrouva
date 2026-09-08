<script setup>
definePageMeta({ middleware: 'admin', layout: 'admin' })

const supabase = useSupabase()
const { villes, communesAbidjan } = useObjectTypes()

// ---------------------------------------------------------------------
// PARTENAIRES (organismes : mairies, commissariats, écoles…)
// ---------------------------------------------------------------------
const partenaires = ref([])
const loadingPartenaires = ref(true)
const savingPartenaire = ref(false)
const editionPartenaireId = ref(null)
const erreurPartenaire = ref('')

const partenaireVide = () => ({ nom: '', contact_email: '', contact_telephone: '', actif: true })
const formPartenaire = reactive(partenaireVide())

const chargerPartenaires = async () => {
  loadingPartenaires.value = true
  const { data } = await supabase.from('partners').select('*').order('created_at', { ascending: false })
  partenaires.value = data || []
  loadingPartenaires.value = false
}

const editerPartenaire = (p) => {
  editionPartenaireId.value = p.id
  Object.assign(formPartenaire, p)
}

const nouveauPartenaire = () => {
  editionPartenaireId.value = null
  Object.assign(formPartenaire, partenaireVide())
  erreurPartenaire.value = ''
}

const enregistrerPartenaire = async () => {
  savingPartenaire.value = true
  erreurPartenaire.value = ''
  const payload = {
    nom: formPartenaire.nom,
    contact_email: formPartenaire.contact_email || null,
    contact_telephone: formPartenaire.contact_telephone || null,
    actif: formPartenaire.actif
  }
  const { error } = editionPartenaireId.value
    ? await supabase.from('partners').update(payload).eq('id', editionPartenaireId.value)
    : await supabase.from('partners').insert(payload)

  if (error) {
    erreurPartenaire.value = "Impossible d'enregistrer : " + error.message
  } else {
    nouveauPartenaire()
    await chargerPartenaires()
    await chargerPoints() // la liste déroulante "partenaire" des points relais doit se mettre à jour
  }
  savingPartenaire.value = false
}

const supprimerPartenaire = async (id) => {
  await supabase.from('partners').delete().eq('id', id)
  await chargerPartenaires()
}

// ---------------------------------------------------------------------
// POINTS RELAIS (lieux physiques où déposer/récupérer un objet)
// ---------------------------------------------------------------------
const points = ref([])
const loadingPoints = ref(true)
const savingPoint = ref(false)
const editionPointId = ref(null)
const erreurPoint = ref('')

const pointVide = () => ({ nom: '', partner_id: '', ville: '', commune: '', adresse: '', horaires: '', actif: true })
const formPoint = reactive(pointVide())

const chargerPoints = async () => {
  loadingPoints.value = true
  const { data } = await supabase
    .from('pickup_points')
    .select('*, partners(nom)')
    .order('created_at', { ascending: false })
  points.value = data || []
  loadingPoints.value = false
}

const editerPoint = (p) => {
  editionPointId.value = p.id
  Object.assign(formPoint, { ...p, partner_id: p.partner_id || '' })
}

const nouveauPoint = () => {
  editionPointId.value = null
  Object.assign(formPoint, pointVide())
  erreurPoint.value = ''
}

const enregistrerPoint = async () => {
  savingPoint.value = true
  erreurPoint.value = ''
  const payload = {
    nom: formPoint.nom,
    partner_id: formPoint.partner_id || null,
    ville: formPoint.ville,
    commune: formPoint.ville === 'Abidjan' ? (formPoint.commune || null) : null,
    adresse: formPoint.adresse || null,
    horaires: formPoint.horaires || null,
    actif: formPoint.actif
  }
  const { error } = editionPointId.value
    ? await supabase.from('pickup_points').update(payload).eq('id', editionPointId.value)
    : await supabase.from('pickup_points').insert(payload)

  if (error) {
    erreurPoint.value = "Impossible d'enregistrer : " + error.message
  } else {
    nouveauPoint()
    await chargerPoints()
  }
  savingPoint.value = false
}

const supprimerPoint = async (id) => {
  await supabase.from('pickup_points').delete().eq('id', id)
  await chargerPoints()
}

onMounted(() => {
  chargerPartenaires()
  chargerPoints()
})
</script>

<template>
  <div class="section py-8 md:py-12">
    <div class="container-app max-w-3xl">
      <h1 class="text-2xl font-bold mb-1">Partenaires &amp; points relais</h1>
      <p class="text-forest-700/70 mb-8">
        Réseau de dépôt/retrait (mairies, commissariats, écoles, entreprises…) utilisé lors de la
        remise d'un objet.
      </p>

      <!-- PARTENAIRES -->
      <h2 class="font-display font-bold text-lg mb-3">Partenaires</h2>
      <form class="card p-5 space-y-4 mb-6" @submit.prevent="enregistrerPartenaire">
        <h3 class="font-display font-semibold text-sm">{{ editionPartenaireId ? 'Modifier le partenaire' : 'Nouveau partenaire' }}</h3>
        <div>
          <label class="label-field">Nom de l'organisme</label>
          <input v-model="formPartenaire.nom" class="input-field" placeholder="Ex. Mairie de Cocody" required />
        </div>
        <div class="grid sm:grid-cols-2 gap-4">
          <div>
            <label class="label-field">E-mail de contact</label>
            <input v-model="formPartenaire.contact_email" type="email" class="input-field" />
          </div>
          <div>
            <label class="label-field">Téléphone de contact</label>
            <input v-model="formPartenaire.contact_telephone" class="input-field" />
          </div>
        </div>
        <label class="flex items-center gap-2 text-sm">
          <input v-model="formPartenaire.actif" type="checkbox" class="h-4 w-4 rounded border-forest-200 text-savane-500" />
          Partenaire actif
        </label>
        <p v-if="erreurPartenaire" class="text-sm text-red-600">{{ erreurPartenaire }}</p>
        <div class="flex gap-3">
          <button type="submit" class="btn-primary" :disabled="savingPartenaire" :class="{ 'opacity-60': savingPartenaire }">
            {{ savingPartenaire ? 'Enregistrement…' : (editionPartenaireId ? 'Mettre à jour' : 'Ajouter') }}
          </button>
          <button v-if="editionPartenaireId" type="button" class="btn-outline" @click="nouveauPartenaire">Annuler</button>
        </div>
      </form>

      <p v-if="loadingPartenaires" class="text-sm text-forest-500 mb-10">Chargement…</p>
      <div v-else class="space-y-3 mb-10">
        <div v-for="p in partenaires" :key="p.id" class="card p-4 flex items-center gap-4">
          <span class="flex h-10 w-10 shrink-0 items-center justify-center rounded-full bg-forest-50 text-forest-700">
            <IconTab name="handshake" class="h-5 w-5" />
          </span>
          <div class="flex-1 min-w-0">
            <p class="font-display font-semibold text-sm truncate">{{ p.nom }}</p>
            <p class="text-xs text-forest-400 truncate">{{ p.contact_email || p.contact_telephone || 'Sans contact' }} · {{ p.actif ? 'actif' : 'inactif' }}</p>
          </div>
          <button class="text-sm text-forest-600 font-semibold" @click="editerPartenaire(p)">Modifier</button>
          <button class="text-sm text-red-500 font-semibold" @click="supprimerPartenaire(p.id)">Supprimer</button>
        </div>
        <p v-if="!partenaires.length" class="text-center py-10 text-forest-500">Aucun partenaire pour le moment.</p>
      </div>

      <!-- POINTS RELAIS -->
      <h2 class="font-display font-bold text-lg mb-3">Points relais</h2>
      <form class="card p-5 space-y-4 mb-6" @submit.prevent="enregistrerPoint">
        <h3 class="font-display font-semibold text-sm">{{ editionPointId ? 'Modifier le point relais' : 'Nouveau point relais' }}</h3>
        <div class="grid sm:grid-cols-2 gap-4">
          <div>
            <label class="label-field">Nom du point</label>
            <input v-model="formPoint.nom" class="input-field" placeholder="Ex. Point Retrouva - Cocody" required />
          </div>
          <div>
            <label class="label-field">Partenaire associé</label>
            <select v-model="formPoint.partner_id" class="input-field">
              <option value="">Aucun (géré directement par Retrouva)</option>
              <option v-for="p in partenaires" :key="p.id" :value="p.id">{{ p.nom }}</option>
            </select>
          </div>
        </div>
        <div class="grid sm:grid-cols-2 gap-4">
          <div>
            <label class="label-field">Ville</label>
            <select v-model="formPoint.ville" class="input-field" required>
              <option value="" disabled>Choisir…</option>
              <option v-for="v in villes" :key="v" :value="v">{{ v }}</option>
            </select>
          </div>
          <div v-if="formPoint.ville === 'Abidjan'">
            <label class="label-field">Commune</label>
            <select v-model="formPoint.commune" class="input-field">
              <option value="" disabled>Choisir…</option>
              <option v-for="c in communesAbidjan" :key="c" :value="c">{{ c }}</option>
            </select>
          </div>
        </div>
        <div>
          <label class="label-field">Adresse</label>
          <input v-model="formPoint.adresse" class="input-field" />
        </div>
        <div>
          <label class="label-field">Horaires</label>
          <input v-model="formPoint.horaires" class="input-field" placeholder="Ex. Lun-Ven 8h-17h" />
        </div>
        <label class="flex items-center gap-2 text-sm">
          <input v-model="formPoint.actif" type="checkbox" class="h-4 w-4 rounded border-forest-200 text-savane-500" />
          Point relais actif
        </label>
        <p v-if="erreurPoint" class="text-sm text-red-600">{{ erreurPoint }}</p>
        <div class="flex gap-3">
          <button type="submit" class="btn-primary" :disabled="savingPoint" :class="{ 'opacity-60': savingPoint }">
            {{ savingPoint ? 'Enregistrement…' : (editionPointId ? 'Mettre à jour' : 'Ajouter') }}
          </button>
          <button v-if="editionPointId" type="button" class="btn-outline" @click="nouveauPoint">Annuler</button>
        </div>
      </form>

      <p v-if="loadingPoints" class="text-sm text-forest-500">Chargement…</p>
      <div v-else class="space-y-3">
        <div v-for="p in points" :key="p.id" class="card p-4 flex items-center gap-4">
          <span class="flex h-10 w-10 shrink-0 items-center justify-center rounded-full bg-forest-50 text-forest-700">
            <IconTab name="pin" class="h-5 w-5" />
          </span>
          <div class="flex-1 min-w-0">
            <p class="font-display font-semibold text-sm truncate">{{ p.nom }}</p>
            <p class="text-xs text-forest-400 truncate">
              {{ p.ville }}<span v-if="p.commune"> · {{ p.commune }}</span>
              <span v-if="p.partners?.nom"> · {{ p.partners.nom }}</span>
              · {{ p.actif ? 'actif' : 'inactif' }}
            </p>
          </div>
          <button class="text-sm text-forest-600 font-semibold" @click="editerPoint(p)">Modifier</button>
          <button class="text-sm text-red-500 font-semibold" @click="supprimerPoint(p.id)">Supprimer</button>
        </div>
        <p v-if="!points.length" class="text-center py-10 text-forest-500">Aucun point relais pour le moment.</p>
      </div>
    </div>
  </div>
</template>
