<script setup>
// Page de connexion dédiée à l'administration — distincte de /connexion
// (qui est réservée aux utilisateurs du site public). Authentification par
// mot de passe uniquement : c'est l'usage normal pour un compte d'équipe.
definePageMeta({ layout: 'admin-auth' })

const route = useRoute()
const { connexion, user, profile } = useAuth()

const email = ref('')
const motdepasse = ref('')
const loading = ref(false)
const error = ref('')

// Staff = comptes ayant un accès quelconque à /admin/** (voir
// useAdminPermissions.js). Le middleware admin.js affine ensuite, page par
// page, ce que chacun peut réellement voir une fois connecté.
const estAdmin = computed(() => profile.value && rolesStaffAdmin.includes(profile.value.role))

watch([user, profile], () => {
  if (user.value && estAdmin.value) navigateTo('/admin')
})

onMounted(() => {
  if (route.query.denied) {
    error.value = "Ce compte n'a pas les droits d'administration."
  }
  if (user.value && estAdmin.value) navigateTo('/admin')
})

const connecter = async () => {
  error.value = ''
  loading.value = true
  try {
    await connexion(email.value, motdepasse.value)
    if (!estAdmin.value) {
      error.value = "Ce compte n'a pas les droits d'administration."
      return
    }
    navigateTo('/admin')
  } catch (e) {
    error.value = 'Identifiants incorrects.'
  } finally {
    loading.value = false
  }
}
</script>

<template>
  <div class="min-h-screen flex items-center justify-center bg-forest-800 px-5">
    <div class="w-full max-w-sm">
      <div class="text-center mb-8">
        <img src="/logo.png" alt="RETROUVA" class="h-14 w-14 mx-auto mb-4" />
        <h1 class="text-xl font-display font-bold text-white">Administration RETROUVA</h1>
        <p class="text-forest-100/60 text-sm mt-1">Espace réservé à l'équipe</p>
      </div>

      <form class="bg-white rounded-2xl p-6 space-y-4 shadow-floating" @submit.prevent="connecter">
        <div>
          <label class="label-field">Adresse e-mail</label>
          <input v-model="email" type="email" class="input-field" required autofocus />
        </div>
        <div>
          <label class="label-field">Mot de passe</label>
          <input v-model="motdepasse" type="password" class="input-field" required />
        </div>
        <p v-if="error" class="text-sm text-red-600">{{ error }}</p>
        <button type="submit" class="btn-primary w-full" :disabled="loading" :class="{ 'opacity-60': loading }">
          {{ loading ? 'Connexion…' : 'Se connecter' }}
        </button>
      </form>

      <NuxtLink to="/" class="block text-center text-forest-100/50 text-xs mt-6 hover:text-white">
        ← Retour au site
      </NuxtLink>
    </div>
  </div>
</template>
