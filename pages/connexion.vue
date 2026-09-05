<script setup>
definePageMeta({ layout: 'auth' })

const route = useRoute()
const { connexion, user } = useAuth()

const destination = computed(() => route.query.next || '/')

const email = ref('')
const password = ref('')
const loading = ref(false)
const error = ref('')

watch(user, (u) => { if (u) navigateTo(destination.value) })
onMounted(() => { if (user.value) navigateTo(destination.value) })

const seConnecter = async () => {
  error.value = ''
  loading.value = true
  try {
    await connexion(email.value, password.value)
    navigateTo(destination.value)
  } catch (e) {
    if (e.message?.toLowerCase().includes('email not confirmed')) {
      navigateTo({ path: '/verifier-email', query: { email: email.value, next: route.query.next } })
      return
    }
    error.value = 'E-mail ou mot de passe incorrect.'
  } finally {
    loading.value = false
  }
}
</script>

<template>
  <div class="auth-split">
    <div class="auth-card">
    <AuthBrandPanel
      image="/marketing/billboard.jpg"
      titre="Bienvenue sur RETROUVA"
      texte="La plateforme ivoirienne qui aide à retrouver, connecter et restituer les objets et documents importants perdus, partout en Côte d'Ivoire."
    />

    <div class="auth-form-panel">
      <div class="w-full max-w-xs mx-auto">
        <NuxtLink to="/" class="flex items-center gap-2 mb-6 lg:hidden">
          <img src="/logo.png" alt="RETROUVA" class="h-8 w-8" />
          <span class="font-display font-extrabold text-base">RETROUV<span class="text-savane-500">A</span></span>
        </NuxtLink>

        <span class="eyebrow">Espace membre</span>
        <h1 class="text-2xl font-bold mb-1 mt-1">Connexion</h1>
        <p class="text-forest-700/70 text-sm mb-6">
          Connectez-vous avec votre e-mail et votre mot de passe.
        </p>

        <form class="space-y-3.5" @submit.prevent="seConnecter">
          <div>
            <label class="label-field">Adresse e-mail</label>
            <input v-model="email" type="email" placeholder="vous@exemple.com" class="input-field" required autofocus />
          </div>
          <div>
            <label class="label-field">Mot de passe</label>
            <input v-model="password" type="password" class="input-field" required />
          </div>
          <p v-if="error" class="text-sm text-red-600">{{ error }}</p>
          <button type="submit" class="btn-primary w-full" :disabled="loading" :class="{ 'opacity-60': loading }">
            <IconTab v-if="!loading" name="check" class="h-4 w-4" />
            {{ loading ? 'Connexion…' : 'Se connecter' }}
          </button>
          <NuxtLink to="/mot-de-passe-oublie" class="block text-center text-sm text-forest-500">
            Mot de passe oublié ?
          </NuxtLink>
        </form>

        <p class="text-sm text-forest-500 mt-8 text-center">
          Pas encore de compte ?
          <NuxtLink to="/inscription" class="text-savane-600 font-semibold">Créer un compte</NuxtLink>
        </p>

        <p class="text-xs text-forest-400 mt-6 text-center">
          En continuant, vous acceptez notre politique de confidentialité et nos conditions d'utilisation.
        </p>
      </div>
    </div>
    </div>
  </div>
</template>
