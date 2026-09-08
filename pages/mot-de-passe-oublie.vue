<script setup>
definePageMeta({ layout: 'auth' })
const { demanderReinitialisation } = useAuth()

const email = ref('')
const loading = ref(false)
const error = ref('')

const envoyer = async () => {
  error.value = ''
  loading.value = true
  try {
    await demanderReinitialisation(email.value)
    navigateTo({ path: '/reinitialiser-mot-de-passe', query: { email: email.value } })
  } catch (e) {
    error.value = e.message || "Impossible d'envoyer le code."
  } finally {
    loading.value = false
  }
}
</script>

<template>
  <div class="auth-split">
    <div class="auth-card">
    <AuthBrandPanel
      titre="Mot de passe oublié"
      texte="Pas de panique — un code de réinitialisation va vous être envoyé par e-mail pour reprendre le contrôle de votre compte en toute sécurité."
    />

    <div class="auth-form-panel">
      <div class="w-full max-w-xs mx-auto">
        <h1 class="text-2xl font-bold mb-2">Réinitialiser mon mot de passe</h1>
        <p class="text-forest-700/70 text-sm mb-8">
          Entrez votre e-mail, nous vous enverrons un code pour définir un nouveau mot de passe.
        </p>

        <form class="space-y-4" @submit.prevent="envoyer">
          <div>
            <label class="label-field">Adresse e-mail</label>
            <input v-model="email" type="email" class="input-field" required autofocus />
          </div>
          <p v-if="error" class="text-sm text-red-600">{{ error }}</p>
          <button type="submit" class="btn-primary w-full" :disabled="loading" :class="{ 'opacity-60': loading }">
            <IconTab v-if="!loading" name="chat" class="h-4 w-4" />
            {{ loading ? 'Envoi…' : 'Recevoir le code' }}
          </button>
        </form>

        <NuxtLink to="/connexion" class="block text-center text-sm text-forest-500 mt-8">
          ← Retour à la connexion
        </NuxtLink>
      </div>
    </div>
    </div>
  </div>
</template>
