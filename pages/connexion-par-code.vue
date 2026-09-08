<script setup>
definePageMeta({ layout: 'auth' })

const route = useRoute()
const { demanderCodeConnexion, verifierCodeConnexion, user } = useAuth()

const destination = computed(() => route.query.next || '/')
const email = ref('')
const code = ref('')
const etape = ref('email') // 'email' -> saisie adresse, 'code' -> saisie code reçu
const loading = ref(false)
const error = ref('')
const renvoye = ref(false)

watch(user, (u) => { if (u) navigateTo(destination.value) })

const envoyerCode = async () => {
  error.value = ''
  loading.value = true
  try {
    await demanderCodeConnexion(email.value)
    etape.value = 'code'
  } catch (e) {
    error.value = e.message || "Impossible d'envoyer le code."
  } finally {
    loading.value = false
  }
}

const verifier = async () => {
  error.value = ''
  loading.value = true
  try {
    await verifierCodeConnexion(email.value, code.value)
    navigateTo(destination.value)
  } catch (e) {
    error.value = e.message || 'Code invalide ou expiré.'
  } finally {
    loading.value = false
  }
}

const renvoyer = async () => {
  error.value = ''
  try {
    await demanderCodeConnexion(email.value)
    renvoye.value = true
    setTimeout(() => (renvoye.value = false), 4000)
  } catch (e) {
    error.value = e.message || "Impossible de renvoyer le code."
  }
}
</script>

<template>
  <div class="auth-split">
    <div class="auth-card">
    <AuthBrandPanel
      titre="Connexion sans mot de passe"
      texte="Recevez un code par e-mail pour vous connecter en toute simplicité, sans avoir à retenir de mot de passe."
    />

    <div class="auth-form-panel">
      <div class="w-full max-w-xs mx-auto">
        <NuxtLink to="/" class="flex items-center gap-2 mb-6 lg:hidden">
          <img src="/logo.png" alt="RETROUVA" class="h-9 w-9" />
          <span class="font-display font-extrabold text-lg">RETROUV<span class="text-savane-500">A</span></span>
        </NuxtLink>

        <template v-if="etape === 'email'">
          <h1 class="text-2xl font-bold mb-2">Connexion par code</h1>
          <p class="text-forest-700/70 text-sm mb-6">
            Saisissez votre adresse e-mail, nous vous enverrons un code de connexion.
          </p>

          <form class="space-y-3.5" @submit.prevent="envoyerCode">
            <div>
              <label class="label-field">Adresse e-mail</label>
              <input v-model="email" type="email" placeholder="vous@exemple.com" class="input-field" required autofocus />
            </div>
            <p v-if="error" class="text-sm text-red-600">{{ error }}</p>
            <button type="submit" class="btn-primary w-full" :disabled="loading" :class="{ 'opacity-60': loading }">
              <IconTab v-if="!loading" name="check" class="h-4 w-4" />
              {{ loading ? 'Envoi…' : 'Recevoir mon code' }}
            </button>
          </form>
        </template>

        <template v-else>
          <h1 class="text-2xl font-bold mb-2">Saisissez le code</h1>
          <p class="text-forest-700/70 text-sm mb-8">
            Un code de connexion a été envoyé à <strong>{{ email }}</strong>.
          </p>

          <form class="space-y-4" @submit.prevent="verifier">
            <div>
              <label class="label-field">Code de vérification</label>
              <input v-model="code" type="text" inputmode="numeric" maxlength="10" class="input-field text-center tracking-[0.3em] text-lg" required autofocus />
            </div>
            <p v-if="error" class="text-sm text-red-600">{{ error }}</p>
            <p v-if="renvoye" class="text-sm text-forest-600">Un nouveau code a été envoyé.</p>
            <button type="submit" class="btn-accent w-full" :disabled="loading" :class="{ 'opacity-60': loading }">
              <IconTab v-if="!loading" name="check" class="h-4 w-4" />
              {{ loading ? 'Vérification…' : 'Se connecter' }}
            </button>
            <button type="button" class="text-sm text-forest-500 w-full text-center" @click="renvoyer">
              Renvoyer le code
            </button>
          </form>
        </template>

        <p class="text-sm text-forest-500 mt-8 text-center">
          <NuxtLink to="/connexion">Se connecter avec un mot de passe</NuxtLink>
        </p>
      </div>
    </div>
    </div>
  </div>
</template>
