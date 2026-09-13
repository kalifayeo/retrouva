<script setup>
const { user } = useAuth()
const supabase = useSupabase()

const motif = ref('')
const details = ref('')
const submitted = ref(false)
const submitting = ref(false)
const submitError = ref('')

const motifs = [
  'Fausse déclaration de propriété',
  'Contenu suspect ou frauduleux',
  'Comportement abusif dans la messagerie',
  'Autre'
]

const submit = async () => {
  submitError.value = ''

  // Un signalement doit être rattaché à un compte (exigé par la base de
  // données) : on redirige vers la connexion si besoin, comme pour les
  // autres formulaires du site.
  if (!user.value) {
    return navigateTo('/connexion?next=/signalement')
  }
  if (!supabase) {
    submitError.value = "Supabase n'est pas configuré (fichier .env manquant). Voir le README."
    return
  }

  submitting.value = true
  const { error } = await supabase.from('reports').insert({
    auteur_id: user.value.id,
    cible_type: 'general',
    motif: motif.value,
    details: details.value.trim() || null
  })
  submitting.value = false

  if (error) {
    submitError.value = "Le signalement n'a pas pu être envoyé. Réessayez dans un instant."
    return
  }

  submitted.value = true
}
</script>

<template>
  <div class="section py-10 md:py-16">
    <div class="container-app max-w-lg">
      <h1 class="text-2xl font-bold mb-2">Signaler un problème</h1>
      <p class="text-forest-700/70 mb-8">
        Aidez-nous à protéger la communauté RETROUVA en signalant tout comportement suspect.
      </p>

      <form v-if="!submitted" class="space-y-5" @submit.prevent="submit">
        <div>
          <label class="label-field">Motif du signalement</label>
          <select v-model="motif" class="input-field" required>
            <option value="" disabled>Sélectionnez un motif</option>
            <option v-for="m in motifs" :key="m" :value="m">{{ m }}</option>
          </select>
        </div>
        <div>
          <label class="label-field">Détails</label>
          <textarea v-model="details" rows="4" class="input-field resize-none" placeholder="Décrivez la situation…" required></textarea>
        </div>
        <p v-if="submitError" class="text-sm text-red-600">{{ submitError }}</p>
        <button type="submit" class="btn-primary w-full" :disabled="submitting">
          {{ submitting ? 'Envoi…' : 'Envoyer le signalement' }}
        </button>
      </form>

      <div v-else class="text-center py-10">
        <span class="mx-auto flex h-16 w-16 items-center justify-center rounded-full bg-forest-50 text-forest-700 mb-5">
          <IconTab name="check" class="h-7 w-7" />
        </span>
        <h2 class="text-xl font-bold mb-2">Signalement envoyé</h2>
        <p class="text-forest-700/70">Notre équipe de modération va l'examiner rapidement.</p>
      </div>
    </div>
  </div>
</template>
