<script setup>
// Historique des dons du donateur connecté — auparavant impossible : un
// don restait anonyme par défaut (aucun lien avec un compte), même si le
// visiteur était connecté au moment de donner. Depuis migration_28, un don
// fait pendant que l'utilisateur est connecté est relié à son compte
// (server/api/dons/creer.post.js), et une policy RLS dédiée
// ("donations_lecture_donateur") lui permet de lire SES dons ici — jamais
// ceux des autres. Les dons faits avant ce correctif, ou fait sans être
// connecté, ne peuvent pas être rattachés rétroactivement.
definePageMeta({ middleware: 'auth' })

const { user } = useAuth()
const supabase = useSupabase()

const dons = ref([])
const loading = ref(true)
const telechargementId = ref(null)
const erreurTelechargement = ref('')

const charger = async () => {
  loading.value = true
  const { data, error } = await supabase
    .from('donations')
    .select('id, reference, montant, statut, type_donateur, raison_sociale, created_at, confirmed_at, payment_methods(nom)')
    .eq('donor_user_id', user.value.id)
    .order('created_at', { ascending: false })

  if (!error) dons.value = data || []
  loading.value = false
}
onMounted(charger)

const libelleStatut = { en_attente: 'En attente', confirme: 'Confirmé', annule: 'Annulé' }
const classeStatut = { en_attente: 'badge-orange', confirme: 'badge-green', annule: 'badge bg-forest-50 text-forest-400' }

const totalConfirme = computed(() =>
  dons.value.filter(d => d.statut === 'confirme').reduce((s, d) => s + Number(d.montant || 0), 0)
)

// Attestation de don (reçu fiscal) — disponible pour tout don confirmé,
// mais surtout utile aux dons "entreprise" pour la comptabilité du
// partenaire. Génération du PDF à la volée côté serveur (voir
// server/api/dons/mes-dons/[id]/attestation.get.js), jamais stockée en clair.
const telechargerAttestation = async (don) => {
  erreurTelechargement.value = ''
  telechargementId.value = don.id
  try {
    const { data: sessionData } = await supabase.auth.getSession()
    const jeton = sessionData?.session?.access_token
    if (!jeton) throw new Error('Session invalide, reconnectez-vous.')

    const config = useRuntimeConfig()
    const reponse = await fetch(`${config.public.apiBaseUrl}/api/dons/mes-dons/${don.id}/attestation`, {
      headers: { Authorization: `Bearer ${jeton}` }
    })
    if (!reponse.ok) {
      const corps = await reponse.json().catch(() => ({}))
      throw new Error(corps.statusMessage || "Impossible de générer l'attestation.")
    }
    const blob = await reponse.blob()
    const url = URL.createObjectURL(blob)
    const lien = document.createElement('a')
    lien.href = url
    lien.download = `attestation-don-${don.reference}.pdf`
    lien.click()
    URL.revokeObjectURL(url)
  } catch (e) {
    erreurTelechargement.value = e.message || "Impossible de générer l'attestation."
  } finally {
    telechargementId.value = null
  }
}
</script>

<template>
  <div class="section py-8 md:py-12">
    <div class="container-app max-w-2xl">
      <h1 class="text-2xl font-bold mb-1">Mes dons</h1>
      <p class="text-forest-700/70 mb-8">
        Historique des dons faits en étant connecté à ce compte. Les dons faits sans être connecté, ou avant
        cette fonctionnalité, ne peuvent pas apparaître ici.
      </p>

      <div class="card p-5 mb-8">
        <p class="text-2xl font-display font-extrabold text-forest-800">{{ totalConfirme.toLocaleString('fr-FR') }} <span class="text-sm font-medium">FCFA</span></p>
        <p class="text-xs text-forest-500">Total de vos dons confirmés</p>
      </div>

      <p v-if="loading" class="text-sm text-forest-500">Chargement…</p>
      <div v-else class="space-y-3">
        <div v-for="d in dons" :key="d.id" class="card p-4">
          <div class="flex items-start justify-between gap-3 mb-2">
            <div class="min-w-0">
              <p class="font-display font-semibold text-sm">{{ Number(d.montant).toLocaleString('fr-FR') }} FCFA</p>
              <p class="text-xs text-forest-400 truncate">
                {{ new Date(d.created_at).toLocaleDateString('fr-FR') }}
                <span v-if="d.payment_methods?.nom"> · {{ d.payment_methods.nom }}</span>
                <span v-if="d.type_donateur === 'entreprise'"> · {{ d.raison_sociale || 'Entreprise' }}</span>
              </p>
              <p class="text-xs text-forest-300 mt-0.5">Réf. {{ d.reference }}</p>
            </div>
            <span :class="classeStatut[d.statut]">{{ libelleStatut[d.statut] }}</span>
          </div>
          <div v-if="d.statut === 'confirme'" class="flex items-center gap-3 mt-3 pt-2 border-t border-forest-50">
            <button
              class="text-xs font-semibold text-forest-700 hover:underline flex items-center gap-1"
              :disabled="telechargementId === d.id"
              @click="telechargerAttestation(d)"
            >
              <IconTab name="card" class="h-3.5 w-3.5" />
              {{ telechargementId === d.id ? 'Génération…' : 'Télécharger l\'attestation (PDF)' }}
            </button>
          </div>
        </div>
        <p v-if="!dons.length" class="text-center py-14 text-forest-500">
          Aucun don enregistré sur ce compte pour le moment.
          <br /><NuxtLink to="/don" class="text-savane-600 font-semibold hover:underline">Faire un don</NuxtLink>
        </p>
      </div>

      <p v-if="erreurTelechargement" class="text-sm text-red-600 mt-4">{{ erreurTelechargement }}</p>
    </div>
  </div>
</template>
