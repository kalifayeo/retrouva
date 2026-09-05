<script setup>
definePageMeta({ middleware: 'auth' })

const { user, profile, signOut, mettreAJourProfil, televerserAvatar } = useAuth()
const { villes, communesAbidjan } = useObjectTypes()

// "Administration" doit apparaître pour tout compte ayant un accès
// quelconque au panneau admin — donc aussi 'moderateur' (voir
// composables/useAdminPermissions.js), pas seulement administrateur/
// super_administrateur comme avant.
const estAdmin = computed(() => profile.value && rolesStaffAdmin.includes(profile.value.role))

const menuBase = [
  { label: 'Mes recherches', to: '/mes-recherches', icon: 'search' },
  { label: 'Mes objets trouvés', to: '/mes-objets-trouves', icon: 'plus' },
  { label: 'Messagerie', to: '/messagerie', icon: 'chat' },
  { label: 'Notifications', to: '/notifications', icon: 'bell' },
  { label: 'Sécurité du compte', to: '/securite', icon: 'shield' },
  { label: 'Signaler un problème', to: '/signalement', icon: 'bell' }
]

const menu = computed(() =>
  estAdmin.value ? [...menuBase, { label: 'Administration', to: '/admin', icon: 'shield' }] : menuBase
)

const initiales = computed(() => {
  const source = profile.value?.nom_affiche || user.value?.email || 'RE'
  return source.slice(0, 2).toUpperCase()
})

const logout = async () => {
  await signOut()
  navigateTo('/')
}

// ---------------------------------------------------------------------
// COMPLÉTUDE DU PROFIL — chaque information manquante réduit la
// confiance que les autres utilisateurs peuvent avoir dans une
// déclaration ou un message. On calcule un pourcentage à partir des
// champs réellement éditables ci-dessous, et on "débloque" un badge de
// confiance visible une fois le profil entièrement renseigné.
// ---------------------------------------------------------------------
// La commune n'existe que pour Abidjan (seule ville découpée en communes,
// voir composables/useObjectTypes.js) : on ne l'exige donc que pour les
// utilisateurs qui ont choisi cette ville, sinon un habitant de Bouaké,
// Daloa, etc. ne pouvait jamais atteindre 100 % et ne débloquait jamais
// le badge confiance.
const elementsProfil = computed(() => {
  const elements = [
    { cle: 'nom_affiche', label: 'Votre nom affiché', rempli: !!profile.value?.nom_affiche },
    { cle: 'telephone', label: 'Un numéro de téléphone', rempli: !!profile.value?.telephone },
    { cle: 'ville', label: 'Votre ville', rempli: !!profile.value?.ville }
  ]
  if (profile.value?.ville === 'Abidjan') {
    elements.push({ cle: 'commune', label: 'Votre commune', rempli: !!profile.value?.commune })
  }
  elements.push({ cle: 'avatar_url', label: 'Une photo de profil', rempli: !!profile.value?.avatar_url })
  return elements
})
const elementsManquants = computed(() => elementsProfil.value.filter(e => !e.rempli))
const pourcentageCompletion = computed(() => {
  const total = elementsProfil.value.length
  const faits = total - elementsManquants.value.length
  return Math.round((faits / total) * 100)
})
const profilComplet = computed(() => pourcentageCompletion.value === 100)

// ---------------------------------------------------------------------
// NOTIFICATION DE DÉBLOCAGE DU BADGE — dès que la mise à jour du profil
// (texte ou photo) fait passer la complétude à 100 %, on informe la
// personne immédiatement par un pop-up visible, en plus de la
// notification déposée automatiquement dans /notifications côté base
// de données (voir supabase/migration_20).
// ---------------------------------------------------------------------
const badgeVientDetreDebloque = ref(false)
let fermetureBadgeTimeout = null

const verifierDeblocageBadge = (etaitCompletAvant) => {
  if (!etaitCompletAvant && profilComplet.value) {
    badgeVientDetreDebloque.value = true
    if (fermetureBadgeTimeout) clearTimeout(fermetureBadgeTimeout)
    fermetureBadgeTimeout = setTimeout(() => { badgeVientDetreDebloque.value = false }, 6000)
  }
}
const fermerNotificationBadge = () => {
  badgeVientDetreDebloque.value = false
  if (fermetureBadgeTimeout) clearTimeout(fermetureBadgeTimeout)
}

// ---------------------------------------------------------------------
// FORMULAIRE DE MODIFICATION
// ---------------------------------------------------------------------
const modification = ref(false)
const form = reactive({ nom_affiche: '', telephone: '', ville: '', commune: '' })
const enregistrement = ref(false)
const erreur = ref('')
const succes = ref(false)

const ouvrirModification = () => {
  form.nom_affiche = profile.value?.nom_affiche || ''
  form.telephone = profile.value?.telephone || ''
  form.ville = profile.value?.ville || ''
  form.commune = profile.value?.commune || ''
  erreur.value = ''
  succes.value = false
  modification.value = true
}

const enregistrer = async () => {
  erreur.value = ''
  succes.value = false
  enregistrement.value = true
  const etaitCompletAvant = profilComplet.value
  try {
    await mettreAJourProfil({
      nom_affiche: form.nom_affiche.trim(),
      telephone: form.telephone.trim() || null,
      ville: form.ville || null,
      commune: form.ville === 'Abidjan' ? (form.commune || null) : null
    })
    succes.value = true
    modification.value = false
    verifierDeblocageBadge(etaitCompletAvant)
  } catch (e) {
    erreur.value = e.message?.includes('duplicate') || e.message?.includes('unique')
      ? 'Ce numéro de téléphone est déjà utilisé par un autre compte.'
      : (e.message || "Impossible d'enregistrer les modifications.")
  } finally {
    enregistrement.value = false
  }
}

// Avatar : sélection immédiate -> envoi direct (pas de champ supplémentaire à valider)
const avatarInput = ref(null)
const televersementAvatar = ref(false)
const erreurAvatar = ref('')

const choisirAvatar = () => avatarInput.value?.click()

const surChoixAvatar = async (e) => {
  const fichier = e.target.files?.[0]
  if (!fichier) return
  erreurAvatar.value = ''
  televersementAvatar.value = true
  const etaitCompletAvant = profilComplet.value
  try {
    await televerserAvatar(fichier)
    verifierDeblocageBadge(etaitCompletAvant)
  } catch (err) {
    erreurAvatar.value = "Impossible d'envoyer la photo. Réessayez avec une image plus légère."
  } finally {
    televersementAvatar.value = false
    e.target.value = ''
  }
}
</script>

<template>
  <div class="section py-8 md:py-12">
    <!-- Pop-up de déblocage du badge confiance -->
    <transition
      enter-active-class="transition duration-300 ease-out"
      enter-from-class="opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95"
      enter-to-class="opacity-100 translate-y-0 sm:scale-100"
      leave-active-class="transition duration-200 ease-in"
      leave-to-class="opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95"
    >
      <div
        v-if="badgeVientDetreDebloque"
        class="fixed z-[70] inset-x-4 bottom-4 sm:inset-x-auto sm:bottom-6 sm:right-6 sm:max-w-sm"
        role="status"
      >
        <div class="relative flex items-start gap-4 rounded-2xl bg-forest-800 text-white shadow-floating p-5 pr-10 overflow-hidden">
          <div class="pointer-events-none absolute -top-8 -right-8 h-24 w-24 rounded-full bg-savane-500/30 blur-2xl"></div>
          <span class="relative flex h-11 w-11 shrink-0 items-center justify-center rounded-full bg-savane-500 text-xl">
            🎁
          </span>
          <div class="relative min-w-0">
            <p class="font-display font-bold text-sm">Badge confiance débloqué !</p>
            <p class="text-xs text-ivoire-100/80 mt-1 leading-relaxed">
              Votre profil est complet. Les personnes avec qui vous échangez vous font désormais davantage confiance.
            </p>
          </div>
          <button
            class="absolute top-3 right-3 text-ivoire-100/60 hover:text-white transition-colors"
            aria-label="Fermer la notification"
            @click="fermerNotificationBadge"
          >
            <IconTab name="close" class="h-4 w-4" />
          </button>
        </div>
      </div>
    </transition>

    <div class="container-app max-w-xl">
      <div class="flex items-center gap-4 mb-6">
        <button
          class="relative group h-16 w-16 shrink-0 rounded-full tap-target"
          :disabled="televersementAvatar"
          @click="choisirAvatar"
          aria-label="Changer la photo de profil"
        >
          <img v-if="profile?.avatar_url" :src="profile.avatar_url" alt="" class="h-16 w-16 rounded-full object-cover" />
          <span v-else class="flex h-16 w-16 items-center justify-center rounded-full bg-forest-800 text-white font-display font-bold text-xl">
            {{ initiales }}
          </span>
          <span class="absolute inset-0 flex items-center justify-center rounded-full bg-forest-900/50 opacity-0 group-hover:opacity-100 transition-opacity">
            <IconTab name="plus" class="h-5 w-5 text-white" />
          </span>
          <span v-if="televersementAvatar" class="absolute inset-0 flex items-center justify-center rounded-full bg-forest-900/60">
            <span class="h-4 w-4 border-2 border-white/40 border-t-white rounded-full animate-spin"></span>
          </span>
        </button>
        <input ref="avatarInput" type="file" accept="image/*" class="hidden" @change="surChoixAvatar" />

        <div class="min-w-0">
          <h1 class="text-lg font-bold truncate flex items-center gap-2">
            {{ profile?.nom_affiche || 'Mon compte RETROUVA' }}
            <BadgeVerifie v-if="profile?.role === 'utilisateur_verifie'" />
          </h1>
          <p class="text-sm text-forest-700/70 truncate">{{ user?.email }}</p>
        </div>
      </div>
      <p v-if="erreurAvatar" class="text-xs text-red-600 -mt-4 mb-6">{{ erreurAvatar }}</p>

      <!-- Coin "Modifier mon profil" -->
      <div class="card p-5 mb-4">
        <div class="flex items-center justify-between mb-1">
          <h2 class="font-display font-semibold text-sm">Modifier mon profil</h2>
          <button v-if="!modification" class="text-xs font-semibold text-savane-600 hover:underline" @click="ouvrirModification">
            Modifier
          </button>
        </div>

        <template v-if="!modification">
          <p class="text-sm text-forest-700/70">Nom, téléphone, ville et commune affichés sur vos déclarations.</p>
          <p v-if="succes" class="text-xs font-semibold text-forest-600 mt-2">✅ Profil mis à jour.</p>
        </template>

        <form v-else class="space-y-3 mt-3" @submit.prevent="enregistrer">
          <div>
            <label class="label-field">Nom affiché</label>
            <input v-model="form.nom_affiche" type="text" class="input-field" placeholder="Ex. Aya K." maxlength="60" required />
          </div>
          <div>
            <label class="label-field">Téléphone</label>
            <input v-model="form.telephone" type="tel" class="input-field" placeholder="07 00 00 00 00" />
          </div>
          <div class="grid grid-cols-2 gap-3">
            <div>
              <label class="label-field">Ville</label>
              <select v-model="form.ville" class="input-field">
                <option value="" disabled>Choisir…</option>
                <option v-for="v in villes" :key="v" :value="v">{{ v }}</option>
              </select>
            </div>
            <div v-if="form.ville === 'Abidjan'">
              <label class="label-field">Commune</label>
              <select v-model="form.commune" class="input-field">
                <option value="" disabled>Choisir…</option>
                <option v-for="c in communesAbidjan" :key="c" :value="c">{{ c }}</option>
              </select>
            </div>
          </div>

          <p v-if="erreur" class="text-xs text-red-600">{{ erreur }}</p>

          <div class="flex gap-2 pt-1">
            <button type="submit" class="btn-accent !py-2.5 text-sm flex-1" :disabled="enregistrement">
              {{ enregistrement ? 'Enregistrement…' : 'Enregistrer' }}
            </button>
            <button type="button" class="btn-outline !py-2.5 text-sm" @click="modification = false">Annuler</button>
          </div>
        </form>
      </div>

      <!-- Complétude du profil : incitation + récompense -->
      <div class="card p-5 mb-6" :class="profilComplet ? 'border-forest-200' : ''">
        <template v-if="profilComplet">
          <div class="flex items-center gap-3">
            <span class="flex h-10 w-10 shrink-0 items-center justify-center rounded-full bg-forest-50 text-forest-700">
              <IconTab name="shield" class="h-5 w-5" />
            </span>
            <div>
              <p class="font-display font-semibold text-sm text-forest-800">🎁 Badge confiance débloqué</p>
              <p class="text-xs text-forest-700/70">Profil complet — vos déclarations inspirent davantage confiance.</p>
            </div>
          </div>
          <span class="badge-green mt-3">✓ Profil complet</span>
        </template>

        <template v-else>
          <div class="flex items-center justify-between mb-2">
            <p class="font-display font-semibold text-sm">Complétez votre profil</p>
            <span class="text-xs font-bold text-savane-600">{{ pourcentageCompletion }} %</span>
          </div>
          <div class="h-2 w-full rounded-full bg-forest-50 overflow-hidden mb-3">
            <div class="h-full bg-brand-gradient transition-all duration-500" :style="{ width: pourcentageCompletion + '%' }"></div>
          </div>
          <p class="text-xs text-forest-700/70 mb-3">
            Un profil complet débloque le <span class="font-semibold text-savane-600">badge confiance 🎁</span> et rassure les personnes avec qui vous êtes mis en relation.
          </p>
          <ul class="space-y-1.5">
            <li v-for="e in elementsManquants" :key="e.cle" class="flex items-center gap-2 text-sm text-forest-700">
              <span class="h-1.5 w-1.5 rounded-full bg-savane-400 shrink-0"></span>
              {{ e.label }}
            </li>
          </ul>
          <button class="text-xs font-semibold text-savane-600 hover:underline mt-3" @click="ouvrirModification">
            Compléter maintenant →
          </button>
        </template>
      </div>

      <div class="card divide-y divide-forest-50">
        <NuxtLink v-for="m in menu" :key="m.to" :to="m.to" class="flex items-center justify-between px-5 py-4 tap-target">
          <span class="flex items-center gap-3 text-sm font-medium text-forest-800">
            <IconTab :name="m.icon" class="h-5 w-5 text-forest-500" /> {{ m.label }}
          </span>
          <IconTab name="arrow" class="h-4 w-4 text-forest-300" />
        </NuxtLink>
      </div>

      <button class="btn-outline w-full mt-6" @click="logout">Se déconnecter</button>
    </div>
  </div>
</template>
