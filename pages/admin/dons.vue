<script setup>
definePageMeta({ middleware: 'admin', layout: 'admin' })

const supabase = useSupabase()
const { user, profile } = useAuth()

// La configuration des moyens de paiement (numéros affichés publiquement
// sur /don) est réservée au super_administrateur ; un administrateur peut
// toujours suivre et confirmer les dons reçus juste en dessous. Rappel :
// confort d'usage côté Nuxt seulement — voir la policy RLS
// "payment_methods_ecriture_super_admin" pour la vraie barrière.
const peutGererMoyensPaiement = computed(() => profile.value?.role === 'super_administrateur')

// ---------------------------------------------------------------------
// MOYENS DE PAIEMENT (numéros affichés sur /don)
// ---------------------------------------------------------------------
const iconesDisponibles = ['card', 'gift', 'handshake']
const methodes = ref([])
const loadingMethodes = ref(true)
const savingMethode = ref(false)
const editionMethodeId = ref(null)
const erreurMethode = ref('')

const methodeVide = () => ({ nom: '', type: 'mobile_money', numero: '', instructions: '', icone: 'card', ordre: (methodes.value.length + 1) * 10, actif: true })
const formMethode = reactive(methodeVide())

const chargerMethodes = async () => {
  loadingMethodes.value = true
  const { data } = await supabase.from('payment_methods').select('*').order('ordre', { ascending: true })
  methodes.value = data || []
  loadingMethodes.value = false
}

const editerMethode = (m) => { editionMethodeId.value = m.id; Object.assign(formMethode, m) }
const nouvelleMethode = () => { editionMethodeId.value = null; Object.assign(formMethode, methodeVide()); erreurMethode.value = '' }

const enregistrerMethode = async () => {
  savingMethode.value = true
  erreurMethode.value = ''
  const payload = {
    nom: formMethode.nom,
    type: formMethode.type,
    numero: formMethode.numero,
    instructions: formMethode.instructions || null,
    icone: formMethode.icone,
    ordre: formMethode.ordre,
    actif: formMethode.actif,
    created_by: user.value.id
  }
  const { error } = editionMethodeId.value
    ? await supabase.from('payment_methods').update(payload).eq('id', editionMethodeId.value)
    : await supabase.from('payment_methods').insert(payload)

  if (error) erreurMethode.value = "Impossible d'enregistrer : " + error.message
  else { nouvelleMethode(); await chargerMethodes() }
  savingMethode.value = false
}

const supprimerMethode = async (id) => {
  if (!confirm('Supprimer ce moyen de paiement ? Il ne sera plus proposé sur la page /don.')) return
  await supabase.from('payment_methods').delete().eq('id', id)
  await chargerMethodes()
}

// ---------------------------------------------------------------------
// DONS ANNONCÉS (aucune passerelle de paiement réelle : chaque don est
// une intention déclarée par le visiteur, confirmée manuellement ici
// une fois le transfert mobile money / Wave vérifié)
// ---------------------------------------------------------------------
const dons = ref([])
const loadingDons = ref(true)
const filtreStatut = ref('tous')

const chargerDons = async () => {
  loadingDons.value = true
  const { data } = await supabase
    .from('donations')
    .select('*, payment_methods(nom)')
    .order('created_at', { ascending: false })
    .limit(200)
  dons.value = data || []
  loadingDons.value = false
}

const donsFiltres = computed(() =>
  filtreStatut.value === 'tous' ? dons.value : dons.value.filter(d => d.statut === filtreStatut.value)
)

const totalConfirme = computed(() =>
  dons.value.filter(d => d.statut === 'confirme').reduce((s, d) => s + Number(d.montant || 0), 0)
)
const totalEnAttente = computed(() =>
  dons.value.filter(d => d.statut === 'en_attente').reduce((s, d) => s + Number(d.montant || 0), 0)
)

const changerStatut = async (don, statut) => {
  const payload = { statut }
  if (statut === 'confirme') { payload.confirmed_by = user.value.id; payload.confirmed_at = new Date().toISOString() }
  await supabase.from('donations').update(payload).eq('id', don.id)
  await chargerDons()
}

const libelleStatut = { en_attente: 'En attente', confirme: 'Confirmé', annule: 'Annulé' }
const classeStatut = { en_attente: 'badge-orange', confirme: 'badge-green', annule: 'badge bg-forest-50 text-forest-400' }

onMounted(() => {
  chargerMethodes()
  chargerDons()
})
</script>

<template>
  <div class="section py-8 md:py-12">
    <div class="container-app max-w-3xl">
      <h1 class="text-2xl font-bold mb-1">Dons</h1>
      <p class="text-forest-700/70 mb-8">
        Moyens de paiement affichés sur la page publique <code class="text-xs">/don</code> et suivi des dons
        annoncés. Aucune passerelle de paiement n'étant connectée, chaque don est une intention déclarée par le
        visiteur : confirmez-le ici une fois le transfert reçu sur le numéro concerné.
      </p>

      <!-- Statistiques rapides -->
      <div class="grid grid-cols-2 gap-4 mb-10">
        <div class="card p-5">
          <p class="text-2xl font-display font-extrabold text-forest-800">{{ totalConfirme.toLocaleString('fr-FR') }} <span class="text-sm font-medium">FCFA</span></p>
          <p class="text-xs text-forest-500">Dons confirmés</p>
        </div>
        <div class="card p-5">
          <p class="text-2xl font-display font-extrabold text-savane-600">{{ totalEnAttente.toLocaleString('fr-FR') }} <span class="text-sm font-medium">FCFA</span></p>
          <p class="text-xs text-forest-500">En attente de confirmation</p>
        </div>
      </div>

      <!-- MOYENS DE PAIEMENT — réservé au super_administrateur -->
      <template v-if="peutGererMoyensPaiement">
      <h2 class="font-display font-bold text-lg mb-3">Moyens de paiement</h2>
      <form class="card p-5 space-y-4 mb-6" @submit.prevent="enregistrerMethode">
        <h3 class="font-display font-semibold text-sm">{{ editionMethodeId ? 'Modifier le moyen de paiement' : 'Nouveau moyen de paiement' }}</h3>
        <div class="grid sm:grid-cols-2 gap-4">
          <div>
            <label class="label-field">Nom</label>
            <input v-model="formMethode.nom" class="input-field" placeholder="Ex. Orange Money" required />
          </div>
          <div>
            <label class="label-field">Type</label>
            <select v-model="formMethode.type" class="input-field">
              <option value="mobile_money">Mobile Money</option>
              <option value="wave">Wave</option>
              <option value="autre">Autre</option>
            </select>
          </div>
        </div>
        <div>
          <label class="label-field">Numéro / identifiant à afficher</label>
          <input v-model="formMethode.numero" class="input-field" placeholder="+225 07 00 00 00 00" required />
        </div>
        <div>
          <label class="label-field">Instructions (code USSD, marche à suivre…)</label>
          <textarea v-model="formMethode.instructions" rows="2" class="input-field resize-none"></textarea>
        </div>
        <div class="grid sm:grid-cols-2 gap-4">
          <div>
            <label class="label-field">Icône</label>
            <select v-model="formMethode.icone" class="input-field">
              <option v-for="i in iconesDisponibles" :key="i" :value="i">{{ i }}</option>
            </select>
          </div>
          <div>
            <label class="label-field">Ordre d'affichage</label>
            <input v-model.number="formMethode.ordre" type="number" class="input-field" />
          </div>
        </div>
        <label class="flex items-center gap-2 text-sm">
          <input v-model="formMethode.actif" type="checkbox" class="h-4 w-4 rounded border-forest-200 text-savane-500" />
          Moyen de paiement actif (visible sur /don)
        </label>
        <p v-if="erreurMethode" class="text-sm text-red-600">{{ erreurMethode }}</p>
        <div class="flex gap-3">
          <button type="submit" class="btn-primary" :disabled="savingMethode" :class="{ 'opacity-60': savingMethode }">
            {{ savingMethode ? 'Enregistrement…' : (editionMethodeId ? 'Mettre à jour' : 'Ajouter') }}
          </button>
          <button v-if="editionMethodeId" type="button" class="btn-outline" @click="nouvelleMethode">Annuler</button>
        </div>
      </form>

      <p v-if="loadingMethodes" class="text-sm text-forest-500 mb-10">Chargement…</p>
      <div v-else class="space-y-3 mb-10">
        <div v-for="m in methodes" :key="m.id" class="card p-4 flex items-center gap-4">
          <span class="flex h-11 w-11 shrink-0 items-center justify-center rounded-full bg-forest-50 text-forest-700">
            <IconTab :name="m.icone" class="h-5 w-5" />
          </span>
          <div class="flex-1 min-w-0">
            <p class="font-display font-semibold text-sm truncate">{{ m.nom }} — {{ m.numero }}</p>
            <p class="text-xs text-forest-400">{{ m.actif ? 'actif' : 'inactif' }} · ordre {{ m.ordre }}</p>
          </div>
          <button class="text-sm text-forest-600 font-semibold" @click="editerMethode(m)">Modifier</button>
          <button class="text-sm text-red-500 font-semibold" @click="supprimerMethode(m.id)">Supprimer</button>
        </div>
        <p v-if="!methodes.length" class="text-center py-10 text-forest-500">Aucun moyen de paiement pour le moment.</p>
      </div>
      </template>

      <!-- DONS ANNONCÉS -->
      <div class="flex items-center justify-between mb-3">
        <h2 class="font-display font-bold text-lg">Dons reçus</h2>
        <select v-model="filtreStatut" class="input-field !py-2 !w-auto text-sm">
          <option value="tous">Tous</option>
          <option value="en_attente">En attente</option>
          <option value="confirme">Confirmés</option>
          <option value="annule">Annulés</option>
        </select>
      </div>

      <p v-if="loadingDons" class="text-sm text-forest-500">Chargement…</p>
      <div v-else class="space-y-3">
        <div v-for="d in donsFiltres" :key="d.id" class="card p-4">
          <div class="flex items-start justify-between gap-3 mb-2">
            <div class="min-w-0">
              <p class="font-display font-semibold text-sm">{{ Number(d.montant).toLocaleString('fr-FR') }} FCFA</p>
              <p class="text-xs text-forest-400 truncate">
                {{ d.nom_donateur || 'Anonyme' }}<span v-if="d.telephone_donateur"> · {{ d.telephone_donateur }}</span>
                <span v-if="d.payment_methods?.nom"> · {{ d.payment_methods.nom }}</span>
              </p>
              <p class="text-xs text-forest-300 mt-0.5">Réf. {{ d.reference }}</p>
            </div>
            <span :class="classeStatut[d.statut]">{{ libelleStatut[d.statut] }}</span>
          </div>
          <p v-if="d.message" class="text-sm text-forest-700/80 italic border-t border-forest-50 pt-2 mt-2">« {{ d.message }} »</p>
          <div class="flex gap-2 mt-3 pt-2 border-t border-forest-50">
            <button v-if="d.statut !== 'confirme'" class="text-xs font-semibold text-forest-700 hover:underline" @click="changerStatut(d, 'confirme')">Marquer confirmé</button>
            <button v-if="d.statut !== 'annule'" class="text-xs font-semibold text-red-500 hover:underline" @click="changerStatut(d, 'annule')">Annuler</button>
            <button v-if="d.statut !== 'en_attente'" class="text-xs font-semibold text-forest-400 hover:underline" @click="changerStatut(d, 'en_attente')">Repasser en attente</button>
          </div>
        </div>
        <p v-if="!donsFiltres.length" class="text-center py-10 text-forest-500">Aucun don pour le moment.</p>
      </div>
    </div>
  </div>
</template>
