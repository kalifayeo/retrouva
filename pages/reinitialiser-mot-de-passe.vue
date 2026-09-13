<script setup>
definePageMeta({ layout: 'auth' })
// Deux chemins possibles :
// 1) L'utilisateur a cliqué le lien reçu par e-mail : Supabase a peut-être déjà
//    établi une session (detectSessionInUrl) -> on affiche directement le
//    formulaire de nouveau mot de passe, sans redemander de code.
// 2) Le lien a été "pré-visité" par le client mail (Gmail notamment) et donc
//    déjà consommé : on propose alors de saisir le code manuellement, ce qui
//    fonctionne toujours puisque le code n'est jamais consommé par un simple
//    aperçu de lien.
const route = useRoute()
const { user, verifierReinitialisation, definirNouveauMotDePasse } = useAuth()

const email = ref(route.query.email || '')
const code = ref('')
const motdepasse = ref('')
const confirmation = ref('')
const loading = ref(false)
const error = ref('')
const succes = ref(false)

const verifierValidite = () => {
  if (motdepasse.value !== confirmation.value) {
    error.value = 'Les mots de passe ne correspondent pas.'
    return false
  }
  if (motdepasse.value.length < 6) {
    error.value = 'Le mot de passe doit contenir au moins 6 caractères.'
    return false
  }
  return true
}

// Chemin 1 : une session existe déjà (lien cliqué avec succès)
const enregistrerViaSession = async () => {
  error.value = ''
  if (!verifierValidite()) return
  loading.value = true
  try {
    await definirNouveauMotDePasse(motdepasse.value)
    succes.value = true
    setTimeout(() => navigateTo('/profil'), 1500)
  } catch (e) {
    error.value = e.message || 'Impossible de mettre à jour le mot de passe.'
  } finally {
    loading.value = false
  }
}

// Chemin 2 : saisie du code reçu par e-mail (recommandé, plus fiable)
const enregistrerViaCode = async () => {
  error.value = ''
  if (!verifierValidite()) return
  loading.value = true
  try {
    await verifierReinitialisation(email.value, code.value, motdepasse.value)
    succes.value = true
    setTimeout(() => navigateTo('/profil'), 1500)
  } catch (e) {
    error.value = e.message || 'Code invalide ou expiré.'
  } finally {
    loading.value = false
  }
}
</script>

<template>
  <div class="auth-split">
    <div class="auth-card">
    <AuthBrandPanel
      titre="Nouveau mot de passe"
      texte="Choisissez un mot de passe robuste. Il vous servira pour toutes vos prochaines connexions à RETROUVA."
    />

    <div class="auth-form-panel">
      <div class="w-full max-w-xs mx-auto">
        <h1 class="text-2xl font-bold mb-6">Définir un nouveau mot de passe</h1>

        <p v-if="succes" class="text-sm text-forest-600 bg-forest-50 rounded-xl px-4 py-4">
          Mot de passe mis à jour, redirection…
        </p>

        <template v-else>
          <!-- Session déjà active via le lien -->
          <form v-if="user" class="space-y-4" @submit.prevent="enregistrerViaSession">
            <div>
              <label class="label-field">Nouveau mot de passe</label>
              <input v-model="motdepasse" type="password" class="input-field" required minlength="6" />
            </div>
            <div>
              <label class="label-field">Confirmer</label>
              <input v-model="confirmation" type="password" class="input-field" required minlength="6" />
            </div>
            <p v-if="error" class="text-sm text-red-600">{{ error }}</p>
            <button type="submit" class="btn-accent w-full" :disabled="loading" :class="{ 'opacity-60': loading }">
              {{ loading ? 'Enregistrement…' : 'Enregistrer' }}
            </button>
          </form>

          <!-- Saisie du code (chemin recommandé) -->
          <form v-else class="space-y-4" @submit.prevent="enregistrerViaCode">
            <p class="text-sm text-forest-600 bg-forest-50 rounded-xl px-4 py-3">
              Saisissez le code reçu par e-mail, ainsi que votre nouveau mot de passe.
            </p>
            <div>
              <label class="label-field">Adresse e-mail</label>
              <input v-model="email" type="email" class="input-field" required />
            </div>
            <div>
              <label class="label-field">Code reçu par e-mail</label>
              <input v-model="code" type="text" inputmode="numeric" maxlength="10" class="input-field text-center tracking-[0.3em] text-lg" required />
            </div>
            <div>
              <label class="label-field">Nouveau mot de passe</label>
              <input v-model="motdepasse" type="password" class="input-field" required minlength="6" />
            </div>
            <div>
              <label class="label-field">Confirmer</label>
              <input v-model="confirmation" type="password" class="input-field" required minlength="6" />
            </div>
            <p v-if="error" class="text-sm text-red-600">{{ error }}</p>
            <button type="submit" class="btn-accent w-full" :disabled="loading" :class="{ 'opacity-60': loading }">
              {{ loading ? 'Enregistrement…' : 'Enregistrer' }}
            </button>
            <NuxtLink to="/mot-de-passe-oublie" class="block text-center text-sm text-forest-500">
              Je n'ai pas reçu de code
            </NuxtLink>
          </form>
        </template>
      </div>
    </div>
    </div>
  </div>
</template>
