<script setup>
definePageMeta({ layout: 'auth' })

const { inscription } = useAuth()
const { villes, communesAbidjan } = useObjectTypes()
const route = useRoute()

const form = reactive({
  nom_affiche: '',
  telephone: '',
  ville: '',
  commune: '',
  email: '',
  password: '',
  confirmation: ''
})

const loading = ref(false)
const error = ref('')

const inscrire = async () => {
  error.value = ''
  if (form.password !== form.confirmation) {
    error.value = 'Les mots de passe ne correspondent pas.'
    return
  }
  if (form.password.length < 6) {
    error.value = 'Le mot de passe doit contenir au moins 6 caractères.'
    return
  }

  loading.value = true
  try {
    await inscription(form.email, form.password, {
      nom_affiche: form.nom_affiche,
      telephone: form.telephone,
      ville: form.ville,
      commune: form.commune
    })
    navigateTo({ path: '/verifier-email', query: { email: form.email, next: route.query.next } })
  } catch (e) {
    error.value = e.message?.includes('already registered')
      ? 'Un compte existe déjà avec cet e-mail. Connectez-vous plutôt.'
      : (e.message || "Impossible de créer le compte.")
  } finally {
    loading.value = false
  }
}
</script>

<template>
  <div class="auth-split">
    <div class="auth-card">
    <AuthBrandPanel
      image="/marketing/storefront.jpg"
      titre="Rejoignez le réseau"
      texte="Chaque inscription renforce le réseau de confiance RETROUVA. Vos informations restent privées et ne sont jamais publiées."
    />

    <div class="auth-form-panel">
      <div class="w-full max-w-xs mx-auto">
        <NuxtLink to="/" class="flex items-center gap-2 mb-4 lg:hidden">
          <img src="/logo.png" alt="RETROUVA" class="h-8 w-8" />
          <span class="font-display font-extrabold text-base">RETROUV<span class="text-savane-500">A</span></span>
        </NuxtLink>

        <span class="eyebrow">Nouveau compte</span>
        <h1 class="text-2xl font-bold mb-1 mt-1">Créer un compte</h1>
        <p class="text-forest-700/70 text-sm mb-5">Rejoignez RETROUVA en quelques informations.</p>

        <form class="space-y-3.5" @submit.prevent="inscrire">
          <div>
            <label class="label-field">Nom complet</label>
            <input v-model="form.nom_affiche" type="text" class="input-field" required autofocus />
          </div>
          <div>
            <label class="label-field">Téléphone</label>
            <input v-model="form.telephone" type="tel" placeholder="+225 07 00 00 00 00" class="input-field" required />
          </div>
          <div class="grid grid-cols-2 gap-3">
            <div>
              <label class="label-field">Ville</label>
              <select v-model="form.ville" class="input-field">
                <option value="" disabled>Choisir</option>
                <option v-for="v in villes" :key="v" :value="v">{{ v }}</option>
              </select>
            </div>
            <div v-if="form.ville === 'Abidjan'">
              <label class="label-field">Commune</label>
              <select v-model="form.commune" class="input-field">
                <option value="" disabled>Choisir</option>
                <option v-for="c in communesAbidjan" :key="c" :value="c">{{ c }}</option>
              </select>
            </div>
          </div>
          <div>
            <label class="label-field">Adresse e-mail</label>
            <input v-model="form.email" type="email" class="input-field" required />
          </div>
          <div class="grid grid-cols-2 gap-3">
            <div>
              <label class="label-field">Mot de passe</label>
              <input v-model="form.password" type="password" class="input-field" required minlength="6" />
            </div>
            <div>
              <label class="label-field">Confirmer</label>
              <input v-model="form.confirmation" type="password" class="input-field" required minlength="6" />
            </div>
          </div>

          <p v-if="error" class="text-sm text-red-600">{{ error }}</p>

          <button type="submit" class="btn-primary w-full" :disabled="loading" :class="{ 'opacity-60': loading }">
            <IconTab v-if="!loading" name="plus" class="h-4 w-4" />
            {{ loading ? 'Création…' : 'Créer mon compte' }}
          </button>

          <p class="text-center text-sm text-forest-500">
            Déjà un compte ?
            <NuxtLink to="/connexion" class="text-savane-600 font-semibold">Se connecter</NuxtLink>
          </p>
        </form>
      </div>
    </div>
    </div>
  </div>
</template>
