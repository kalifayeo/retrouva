<script setup>
definePageMeta({ middleware: 'admin', layout: 'admin' })

const supabase = useSupabase()
const settings = ref({})
const loading = ref(true)
const saving = ref(false)
const saved = ref(false)

// Chaque champ correspond à une clé de la table site_settings (même
// principe que /admin/contenu). Tant qu'un champ n'est pas rempli, la
// page publique affiche un texte "[à compléter]" par défaut — rien ne
// casse si l'admin ne remplit pas tout d'un coup.
const champsEditeur = [
  { cle: 'mentions_raison_sociale', label: 'Raison sociale / nom' },
  { cle: 'mentions_forme_juridique', label: 'Forme juridique', placeholder: 'ex. entreprise individuelle, SARL, SA' },
  { cle: 'mentions_rccm', label: 'Numéro RCCM' },
  { cle: 'mentions_ncc', label: 'Numéro de compte contribuable (NCC)' },
  { cle: 'mentions_siege_social', label: 'Siège social (adresse complète)' },
  { cle: 'mentions_email', label: 'E-mail de contact' },
  { cle: 'mentions_telephone', label: 'Téléphone' },
  { cle: 'mentions_directeur_publication', label: 'Directeur de la publication' }
]

const champsHebergement = [
  { cle: 'mentions_hebergeur_nom', label: "Nom de l'hébergeur du site", placeholder: 'ex. Vercel Inc.' },
  { cle: 'mentions_hebergeur_adresse', label: "Adresse de l'hébergeur" }
]

const toutesLesCles = [...champsEditeur, ...champsHebergement].map(c => c.cle)

const charger = async () => {
  loading.value = true
  const { data } = await supabase.from('site_settings').select('cle, valeur').in('cle', toutesLesCles)
  const map = {}
  for (const row of data || []) map[row.cle] = row.valeur
  settings.value = Object.fromEntries(toutesLesCles.map(c => [c, map[c] || '']))
  loading.value = false
}

const enregistrer = async () => {
  saving.value = true
  saved.value = false
  for (const cle of toutesLesCles) {
    await supabase.from('site_settings').upsert({ cle, valeur: settings.value[cle] || '' })
  }
  saving.value = false
  saved.value = true
  setTimeout(() => (saved.value = false), 2500)
}

onMounted(charger)
</script>

<template>
  <div class="section py-8 md:py-12">
    <div class="container-app max-w-2xl">
      <h1 class="text-2xl font-bold mb-1">Mentions légales</h1>
      <p class="text-forest-700/70 mb-6">
        Ces informations alimentent directement la page publique
        <NuxtLink to="/mentions-legales" target="_blank" class="text-savane-600 font-semibold">/mentions-legales</NuxtLink>.
        Tant qu'un champ reste vide, un texte « à compléter » s'affiche à sa place.
      </p>

      <p v-if="loading" class="text-sm text-forest-500">Chargement…</p>

      <form v-else class="space-y-8" @submit.prevent="enregistrer">
        <div class="card p-5 space-y-4">
          <h2 class="font-display font-semibold">Éditeur du site</h2>
          <div v-for="c in champsEditeur" :key="c.cle">
            <label class="label-field">{{ c.label }}</label>
            <input v-model="settings[c.cle]" class="input-field" :placeholder="c.placeholder || ''" />
          </div>
        </div>

        <div class="card p-5 space-y-4">
          <h2 class="font-display font-semibold">Hébergement</h2>
          <p class="text-sm text-forest-500">
            La base de données et les fichiers utilisateurs sont hébergés par Supabase — cette
            mention reste fixe sur la page publique. Seul l'hébergeur du site (front-end) est à
            renseigner ici.
          </p>
          <div v-for="c in champsHebergement" :key="c.cle">
            <label class="label-field">{{ c.label }}</label>
            <input v-model="settings[c.cle]" class="input-field" :placeholder="c.placeholder || ''" />
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
