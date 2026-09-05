<script setup>
const { objectTypes } = useObjectTypes()
const supabase = useSupabase()

const contenu = reactive({
  hero_titre: "Vous avez perdu un objet\u00a0?",
  hero_titre_accent: "Quelqu'un l'a peut-être retrouvé.",
  hero_sous_titre: "RETROUVA connecte les personnes qui perdent et celles qui trouvent des documents et objets importants — CNI, permis, cartes, téléphones, clés — partout en Côte d'Ivoire.",
  hero_background_type: 'animation',
  hero_video_url: '',
  hero_backdrop_url: ''
})

const typeInfo = (id) => objectTypes.find(t => t.id === id) || { label: id, image: '' }

const statsDirect = reactive({
  trouves: null,
  perdus: null,
  utilisateurs: null,
  villes: null
})

const recents = ref([])
const chargementDonnees = ref(true)
const indexAnnonce = ref(0)
let intervalAnnonce = null

const annonceActuelle = computed(() => recents.value[indexAnnonce.value] || null)

const demarrerRotationAnnonces = () => {
  if (intervalAnnonce) clearInterval(intervalAnnonce)
  if (recents.value.length > 1) {
    intervalAnnonce = setInterval(() => {
      indexAnnonce.value = (indexAnnonce.value + 1) % recents.value.length
    }, 4500)
  }
}

onBeforeUnmount(() => { if (intervalAnnonce) clearInterval(intervalAnnonce) })

const chargerDonneesDirectes = async () => {
  if (!supabase) { chargementDonnees.value = false; return }

  try {
    const [stats, recentsRes] = await Promise.all([
      supabase.rpc('public_stats'),
      supabase.from('found_reports').select('id, object_type_id, ville, commune, created_at').eq('statut', 'active').order('created_at', { ascending: false }).limit(5)
    ])

    if (stats.data) {
      statsDirect.trouves = stats.data.trouves
      statsDirect.perdus = stats.data.perdus
      statsDirect.utilisateurs = stats.data.utilisateurs
      statsDirect.villes = stats.data.villes
    }
    recents.value = recentsRes.data || []
    demarrerRotationAnnonces()
  } finally {
    chargementDonnees.value = false
  }
}

onMounted(async () => {
  if (!supabase) return
  const { data } = await supabase.from('site_settings').select('cle, valeur')
  for (const row of data || []) {
    if (row.valeur) contenu[row.cle] = row.valeur
  }
  chargerDonneesDirectes()
})

const steps = [
  { title: 'Déclarez', text: "Décrivez l'objet perdu ou trouvé en quelques informations, sans exposer de données sensibles.", icon: 'pin' },
  { title: 'Nous rapprochons', text: 'Notre moteur compare automatiquement les déclarations et calcule un score de correspondance.', icon: 'search' },
  { title: 'Vérification', text: 'Le propriétaire confirme son identité avec des éléments que seul lui peut connaître.', icon: 'shield' },
  { title: 'Restitution', text: "Mise en relation sécurisée, puis remise de l'objet en main propre ou via un point relais.", icon: 'handshake' }
]

const temoignages = [
  { nom: 'Aminata K.', ville: 'Cocody', initiales: 'AK', citation: "J'ai retrouvé ma carte d'identité en deux jours, sans donner mon numéro à un inconnu." },
  { nom: 'Yves-Marie D.', ville: 'Yopougon', initiales: 'YD', citation: "J'avais trouvé un portefeuille au marché. La plateforme m'a mis en relation en toute sécurité." },
  { nom: 'Fatou S.', ville: 'Plateau', initiales: 'FS', citation: "Simple, rassurant, et gratuit. Exactement ce qui manquait à Abidjan." }
]

const securiteInfos = [
  { titre: 'Score ≠ preuve', texte: "Un fort taux de correspondance signale une piste sérieuse, jamais une preuve de propriété.", icon: 'search' },
  { titre: 'Vérification obligatoire', texte: "Avant toute mise en relation, le demandeur doit confirmer des détails que seul le propriétaire connaît.", icon: 'shield' },
  { titre: 'Données jamais publiées', texte: "Numéro de CNI, téléphone, adresse : ces informations restent privées et ne sont jamais affichées publiquement.", icon: 'check' },
  { titre: 'Messagerie protégée', texte: "Vous échangez sans révéler vos coordonnées personnelles, jusqu'à ce que vous décidiez de les partager.", icon: 'chat' }
]

const partenairesTypes = [
  { nom: 'Commissariats', icon: 'shield' },
  { nom: 'Mairies', icon: 'pin' },
  { nom: 'Écoles & universités', icon: 'card' },
  { nom: 'Gares & transporteurs', icon: 'arrow' },
  { nom: 'Centres commerciaux', icon: 'search' },
  { nom: 'Entreprises', icon: 'handshake' }
]

const faqApercu = [
  { q: 'Comment RETROUVA calcule-t-il une correspondance ?', r: "En combinant catégorie, ville, commune, date et description de l'objet pour proposer un score de similarité." },
  { q: 'Mes données personnelles sont-elles visibles publiquement ?', r: "Non. Seules les informations non sensibles apparaissent publiquement ; le reste sert uniquement à la vérification." },
  { q: 'Comment se passe la remise de l\'objet ?', r: "En main propre, dans un point relais, ou chez un partenaire RETROUVA, selon ce qui vous convient." }
]

const rechercheRapide = ref('')
const lancerRechercheRapide = () => {
  if (!rechercheRapide.value.trim()) return
  navigateTo({ path: '/recherche', query: { q: rechercheRapide.value.trim() } })
}
</script>

<template>
  <div>
    <!-- BANDEAU D'ANNONCE EN DIRECT (rotation automatique) -->
    <div v-if="annonceActuelle" class="bg-forest-800 text-white py-2.5 px-4 overflow-hidden">
      <transition
        mode="out-in"
        enter-active-class="transition duration-300 ease-out"
        enter-from-class="opacity-0 translate-y-1"
        enter-to-class="opacity-100 translate-y-0"
        leave-active-class="transition duration-200 ease-in"
        leave-to-class="opacity-0 -translate-y-1"
      >
        <NuxtLink :key="annonceActuelle.id" to="/recherche" class="flex items-center justify-center gap-2 text-xs sm:text-sm text-center hover:text-savane-300 transition-colors">
          <IconTab name="bell" class="h-3.5 w-3.5 text-savane-400 shrink-0" />
          <span class="truncate">
            {{ typeInfo(annonceActuelle.object_type_id).label }} trouvé
            {{ annonceActuelle.commune ? `à ${annonceActuelle.commune}` : `à ${annonceActuelle.ville}` }}
            · {{ tempsRelatif(annonceActuelle.created_at) }}
          </span>
          <span class="hidden sm:inline font-semibold text-savane-400 shrink-0">Vérifier →</span>
        </NuxtLink>
      </transition>
      <div v-if="recents.length > 1" class="flex items-center justify-center gap-1.5 mt-1.5">
        <span
          v-for="(r, i) in recents" :key="r.id"
          class="h-1 rounded-full transition-all"
          :class="i === indexAnnonce ? 'w-4 bg-savane-400' : 'w-1 bg-white/30'"
        ></span>
      </div>
    </div>

    <!-- HERO -->
    <section class="section pt-4 pb-8 md:pt-6 md:pb-12 bg-brand-gradient-soft relative overflow-hidden">
      <!-- Image/GIF de fond (optionnelle, gérée depuis l'admin) : couvre toute
           la section, avec un dégradé de transition pour garder le texte
           lisible côté gauche. -->
      <template v-if="contenu.hero_backdrop_url">
        <img
          :src="contenu.hero_backdrop_url"
          alt=""
          class="pointer-events-none absolute inset-0 w-full h-full object-cover"
        />
        <div class="pointer-events-none absolute inset-0 bg-forest-900/55 md:bg-gradient-to-r md:from-forest-900/80 md:via-forest-900/45 md:to-transparent"></div>
      </template>
      <template v-else>
        <div class="pointer-events-none absolute -top-24 -right-24 h-72 w-72 rounded-full bg-savane-300/20 blur-3xl"></div>
        <div class="pointer-events-none absolute -bottom-32 -left-16 h-80 w-80 rounded-full bg-forest-300/20 blur-3xl"></div>
      </template>

      <div class="container-app grid md:grid-cols-2 gap-10 xl:gap-20 items-center relative">
        <div class="text-center md:text-left">
          <div class="flex flex-wrap items-center justify-center md:justify-start gap-2 mb-5">
            <span class="badge-orange">
              <IconTab name="pin" class="h-3.5 w-3.5" /> Côte d'Ivoire
            </span>
            <span v-if="statsDirect.utilisateurs" class="badge-green">
              <IconTab name="check" class="h-3.5 w-3.5" /> +{{ statsDirect.utilisateurs }} citoyens nous font confiance
            </span>
          </div>
          <h1
            class="text-3xl sm:text-4xl md:text-5xl xl:text-[3.25rem] font-extrabold leading-tight mb-4"
            :class="contenu.hero_backdrop_url ? 'text-ivoire-50' : ''"
          >
            {{ contenu.hero_titre }}
            <span class="text-savane-500">{{ contenu.hero_titre_accent }}</span>
          </h1>
          <p
            class="text-base md:text-lg xl:text-xl mb-8 max-w-md xl:max-w-lg mx-auto md:mx-0"
            :class="contenu.hero_backdrop_url ? 'text-ivoire-100/90' : 'text-forest-700'"
          >
            {{ contenu.hero_sous_titre }}
          </p>

          <div class="grid grid-cols-2 gap-3 sm:flex sm:flex-wrap justify-center md:justify-start max-w-xs sm:max-w-none mx-auto md:mx-0">
            <NuxtLink to="/perdu" class="btn-primary">
              <IconTab name="search" class="h-4 w-4" /> J'ai perdu
            </NuxtLink>
            <NuxtLink to="/trouve" class="btn-accent">
              <IconTab name="plus" class="h-4 w-4" /> J'ai trouvé
            </NuxtLink>
          </div>

          <div
            class="mt-8 flex items-center justify-center md:justify-start gap-5 text-xs"
            :class="contenu.hero_backdrop_url ? 'text-ivoire-100/90' : 'text-forest-700'"
          >
            <span class="flex items-center gap-1.5"><IconTab name="shield" class="h-4 w-4" :class="contenu.hero_backdrop_url ? 'text-ivoire-100' : 'text-forest-500'" /> Données protégées</span>
            <span class="flex items-center gap-1.5"><IconTab name="check" class="h-4 w-4" :class="contenu.hero_backdrop_url ? 'text-ivoire-100' : 'text-forest-500'" /> Vérification avant restitution</span>
          </div>
        </div>

        <div class="relative flex justify-center">

          <!-- Mode vidéo : la vidéo devient le visuel principal, en carte
               large et nette, avec un petit badge du logo par-dessus. -->
          <template v-if="contenu.hero_background_type === 'video' && contenu.hero_video_url">
            <div class="relative z-10 w-full max-w-sm sm:max-w-md xl:max-w-lg aspect-[4/3] overflow-hidden shadow-floating">
              <video
                :src="contenu.hero_video_url"
                autoplay muted loop playsinline
                class="absolute inset-0 w-full h-full object-cover"
              ></video>
              <div class="absolute inset-0 bg-gradient-to-t from-forest-900/40 via-transparent to-transparent"></div>
              <div class="absolute bottom-4 left-4 flex items-center gap-2 bg-white/95 backdrop-blur px-3 py-2 shadow-card">
                <img src="/logo.png" alt="RETROUVA" class="h-6 w-6 object-contain rounded" />
                <span class="font-display font-bold text-sm text-forest-800">
                  RETROUV<span class="text-savane-500">A</span>
                </span>
              </div>
            </div>
          </template>

          <!-- Mode animation (par défaut) : anneaux + orbes derrière le logo -->
          <template v-else>
            <div class="absolute inset-0 z-0 flex items-center justify-center pointer-events-none">
              <div class="hero-ring hero-ring-1"></div>
              <div class="hero-ring hero-ring-2"></div>
              <div class="hero-orb hero-orb-a"></div>
              <div class="hero-orb hero-orb-b"></div>
              <div class="hero-orb hero-orb-c"></div>
            </div>
            <img src="/logo.png" alt="RETROUVA" class="relative z-10 w-56 sm:w-72 md:w-80 xl:w-[26rem] drop-shadow-xl hero-float" />
          </template>
        </div>
      </div>
    </section>

    <!-- RECHERCHE RAPIDE -->
    <section class="section -mt-8 md:-mt-10 relative z-10">
      <div class="container-app card p-4 sm:p-5">
        <form class="flex flex-col sm:flex-row gap-3" @submit.prevent="lancerRechercheRapide">
          <div class="flex-1 flex items-center gap-3 bg-ivoire-100 px-4 py-3">
            <IconTab name="search" class="h-5 w-5 text-forest-400 shrink-0" />
            <input
              v-model="rechercheRapide"
              type="text"
              placeholder="Type d'objet, ville, commune…"
              class="bg-transparent w-full text-sm outline-none placeholder:text-forest-300"
            />
          </div>
          <button type="submit" class="btn-primary shrink-0">
            <IconTab name="search" class="h-4 w-4" /> Rechercher
          </button>
        </form>
        <div class="flex flex-wrap gap-2 mt-3">
          <button
            v-for="chip in ['CNI', 'Passeport', 'Permis', 'Téléphone']"
            :key="chip"
            type="button"
            class="text-xs font-semibold text-forest-600 bg-forest-50 hover:bg-forest-100 rounded-full px-3 py-1.5 transition-colors"
            @click="rechercheRapide = chip; lancerRechercheRapide()"
          >
            {{ chip }}
          </button>
        </div>
      </div>
    </section>

    <!-- BANNIÈRE D'ANNONCE -->
    <section class="section pt-5 md:pt-6">
      <div class="container-app">
        <SiteBanner position="accueil" />
      </div>
    </section>

    <!-- TYPES D'OBJETS -->
    <section class="section py-7 md:py-9">
      <div class="container-app">
        <span class="eyebrow">Que recherchez-vous&nbsp;?</span>
        <div class="section-divider my-3"></div>
        <h2 class="text-2xl md:text-3xl font-bold mb-2">Quel type d'objet est concerné&nbsp;?</h2>
        <p class="text-forest-700/70 mb-5">Sélectionnez une catégorie pour commencer une déclaration.</p>
        <div class="grid grid-cols-3 sm:grid-cols-4 md:grid-cols-6 xl:grid-cols-8 gap-3 xl:gap-4">
          <NuxtLink v-for="t in objectTypes" :key="t.id" :to="`/declarer?type=${t.id}`" class="group">
            <ObjectTypeCard :label="t.label" :icon="t.icon" :image="t.image" />
          </NuxtLink>
        </div>
      </div>
    </section>

    <!-- COMMENT CA MARCHE -->
    <section class="section py-8 md:py-10 bg-forest-800 text-white">
      <div class="container-app">
        <span class="eyebrow !text-savane-400">Le parcours</span>
        <div class="section-divider my-3"></div>
        <h2 class="text-2xl md:text-3xl font-bold mb-2 text-white">Comment ça marche</h2>
        <p class="text-forest-100/70 mb-6 max-w-lg">
          Un parcours pensé pour la confiance : chaque étape protège vos informations jusqu'à la
          restitution effective.
        </p>

        <div class="grid sm:grid-cols-2 lg:grid-cols-4 gap-5">
          <div
            v-for="(s, i) in steps"
            :key="s.title"
            class="bg-forest-700/60 p-5 border border-white/5 hover:border-savane-500/40 transition-colors duration-300"
          >
            <div class="flex items-center gap-3 mb-3">
              <span class="flex h-10 w-10 items-center justify-center rounded-full bg-savane-500 text-white shrink-0">
                <IconTab :name="s.icon" class="h-5 w-5" />
              </span>
              <span class="text-forest-100/40 text-2xl font-display font-extrabold">{{ String(i + 1).padStart(2, '0') }}</span>
            </div>
            <h3 class="font-display font-semibold text-white mb-1">{{ s.title }}</h3>
            <p class="text-sm text-forest-100/70 leading-relaxed">{{ s.text }}</p>
          </div>
        </div>
      </div>
    </section>

    <!-- NOTRE IMPACT -->
    <section class="section py-7 md:py-9">
      <div class="container-app">
        <span class="eyebrow">En temps réel</span>
        <div class="section-divider my-3"></div>
        <h2 class="text-2xl md:text-3xl font-bold mb-2">Notre impact</h2>
        <p class="text-forest-700/70 mb-5">Ensemble, nous aidons les Ivoiriens à retrouver leurs objets perdus.</p>

        <div class="grid lg:grid-cols-5 gap-5">
          <!-- Flux en direct -->
          <div class="lg:col-span-3 card overflow-hidden">
            <div class="flex items-center justify-between bg-forest-800 text-white px-5 py-4">
              <span class="flex items-center gap-2.5 text-sm font-display font-semibold tracking-wide">
                <span class="h-2 w-2 rounded-full bg-savane-400 animate-pulse"></span>
                Objets trouvés récemment
              </span>
              <NuxtLink to="/recherche" class="flex items-center gap-1 text-xs font-semibold text-forest-100/70 hover:text-white transition-colors">
                Voir tout <IconTab name="arrow" class="h-3 w-3" />
              </NuxtLink>
            </div>
            <div class="divide-y divide-forest-50">
              <template v-if="chargementDonnees">
                <div v-for="n in 3" :key="n" class="flex items-center gap-3 px-5 py-4 animate-pulse">
                  <span class="h-10 w-10 shrink-0 rounded-full bg-forest-50"></span>
                  <span class="flex-1 min-w-0 space-y-2">
                    <span class="block h-3 w-2/3 rounded-full bg-forest-50"></span>
                    <span class="block h-2.5 w-1/3 rounded-full bg-forest-50"></span>
                  </span>
                </div>
              </template>
              <template v-else>
                <NuxtLink
                  v-for="r in recents"
                  :key="r.id"
                  to="/recherche"
                  class="flex items-center gap-3 px-5 py-4 hover:bg-ivoire-100 dark:hover:bg-forest-800 transition-colors"
                >
                  <span class="flex h-10 w-10 shrink-0 items-center justify-center rounded-full bg-forest-50 text-forest-700">
                    <IconTab name="card" class="h-4 w-4" />
                  </span>
                  <span class="flex-1 min-w-0">
                    <span class="block text-sm font-display font-semibold text-forest-800 truncate">{{ typeInfo(r.object_type_id).label }} trouvé</span>
                    <span class="flex items-center gap-1 text-xs text-forest-400 mt-0.5">
                      <IconTab name="pin" class="h-3 w-3" />
                      {{ r.commune ? `${r.commune}, ` : '' }}{{ r.ville }} · {{ tempsRelatif(r.created_at) }}
                    </span>
                  </span>
                  <IconTab name="arrow" class="h-3.5 w-3.5 text-forest-300 shrink-0" />
                </NuxtLink>
                <p v-if="!recents.length" class="px-5 py-8 text-sm text-forest-400 text-center">
                  Aucune déclaration pour le moment — soyez le premier à en publier une !
                </p>
              </template>
            </div>
          </div>

          <!-- Statistiques -->
          <div class="lg:col-span-2 card p-5 card-hover">
            <p class="flex items-center gap-1.5 text-[11px] font-bold uppercase tracking-widest text-forest-400 mb-5">
              <IconTab name="check" class="h-3 w-3" /> Statistiques en direct
            </p>
            <div class="grid grid-cols-2 gap-4 divide-y divide-x divide-forest-50 [&>div]:pt-0">
              <div class="pb-4 pr-2">
                <span class="flex h-9 w-9 items-center justify-center rounded-full bg-forest-50 text-forest-600 mb-2.5">
                  <IconTab name="check" class="h-4 w-4" />
                </span>
                <div v-if="chargementDonnees" class="h-8 w-12 bg-forest-50 animate-pulse"></div>
                <div v-else class="text-3xl font-display font-extrabold text-forest-800 tracking-tight">{{ statsDirect.trouves ?? '—' }}</div>
                <div class="text-[11px] font-semibold uppercase tracking-wide text-forest-500 mt-1">Objets trouvés</div>
              </div>
              <div class="pb-4 pl-4">
                <span class="flex h-9 w-9 items-center justify-center rounded-full bg-savane-50 text-savane-600 mb-2.5">
                  <IconTab name="search" class="h-4 w-4" />
                </span>
                <div v-if="chargementDonnees" class="h-8 w-12 bg-savane-50 animate-pulse"></div>
                <div v-else class="text-3xl font-display font-extrabold text-forest-800 tracking-tight">{{ statsDirect.perdus ?? '—' }}</div>
                <div class="text-[11px] font-semibold uppercase tracking-wide text-forest-500 mt-1">Recherches actives</div>
              </div>
              <div class="pt-4 pr-2">
                <span class="flex h-9 w-9 items-center justify-center rounded-full bg-forest-50 text-forest-600 mb-2.5">
                  <IconTab name="user" class="h-4 w-4" />
                </span>
                <div v-if="chargementDonnees" class="h-8 w-12 bg-forest-50 animate-pulse"></div>
                <div v-else class="text-3xl font-display font-extrabold text-forest-800 tracking-tight">{{ statsDirect.utilisateurs ?? '—' }}</div>
                <div class="text-[11px] font-semibold uppercase tracking-wide text-forest-500 mt-1">Citoyens inscrits</div>
              </div>
              <div class="pt-4 pl-4">
                <span class="flex h-9 w-9 items-center justify-center rounded-full bg-savane-50 text-savane-600 mb-2.5">
                  <IconTab name="pin" class="h-4 w-4" />
                </span>
                <div v-if="chargementDonnees" class="h-8 w-12 bg-savane-50 animate-pulse"></div>
                <div v-else class="text-3xl font-display font-extrabold text-forest-800 tracking-tight">{{ statsDirect.villes ?? '—' }}</div>
                <div class="text-[11px] font-semibold uppercase tracking-wide text-forest-500 mt-1">Villes couvertes</div>
              </div>
            </div>
            <p class="flex items-center gap-1.5 text-xs font-medium text-forest-400 mt-5">
              <span class="h-1.5 w-1.5 rounded-full bg-forest-500 animate-pulse"></span> Données en direct
            </p>
          </div>
        </div>
      </div>
    </section>

    <!-- CARTE INTERACTIVE -->
    <section class="section py-8 md:py-10 bg-forest-900 text-white mx-4 sm:mx-5 lg:mx-8">
      <div class="container-app grid lg:grid-cols-2 gap-8 items-center">
        <div>
          <span class="badge-orange mb-4"><IconTab name="pin" class="h-3.5 w-3.5" /> Nouvelle fonctionnalité</span>
          <h2 class="text-2xl md:text-3xl font-bold text-white mb-3">Explorez la carte interactive</h2>
          <p class="text-forest-100/70 mb-6 max-w-md">
            Visualisez tous les objets perdus et trouvés sur une carte de la Côte d'Ivoire.
            Filtrez par ville et repérez les zones les plus actives.
          </p>
          <div class="flex gap-8 mb-6">
            <div>
              <div class="text-2xl font-display font-extrabold text-[#F87171]">{{ statsDirect.perdus ?? '—' }}</div>
              <div class="text-xs text-forest-100/60">Objets perdus</div>
            </div>
            <div>
              <div class="text-2xl font-display font-extrabold text-savane-400">{{ statsDirect.trouves ?? '—' }}</div>
              <div class="text-xs text-forest-100/60">Objets trouvés</div>
            </div>
          </div>
          <NuxtLink to="/carte" class="btn-accent">
            Voir la carte <IconTab name="arrow" class="h-4 w-4" />
          </NuxtLink>
        </div>

        <div class="card p-2 overflow-hidden">
          <ClientOnly>
            <RetrouvaCarte :interactive="false" hauteur="320px" />
          </ClientOnly>
        </div>
      </div>
    </section>

    <!-- ESPACE PARTENAIRE / PUBLICITÉ -->
    <section class="section py-7 md:py-9">
      <div class="container-app">
        <SiteBanner position="accueil_pub" />
      </div>
    </section>

    <!-- SÉCURITÉ & VÉRIFICATION (2 colonnes) -->
    <section class="section py-8 md:py-10">
      <div class="container-app grid lg:grid-cols-2 gap-8 lg:gap-12 items-start">
        <div>
          <span class="eyebrow">Confiance &amp; sécurité</span>
          <div class="section-divider my-3"></div>
          <h2 class="text-2xl md:text-3xl font-bold mb-3">Un score élevé ne suffit jamais</h2>
          <p class="text-forest-700/70 mb-5 max-w-md">
            Notre moteur compare plusieurs critères — catégorie, ville, commune, date et
            description — pour calculer un score de correspondance. Mais ce score n'est qu'un
            point de départ&nbsp;: c'est la vérification qui protège chaque restitution.
          </p>
          <ul class="space-y-3 mb-6">
            <li class="flex items-start gap-2.5 text-sm text-forest-700/80">
              <IconTab name="check" class="h-4 w-4 text-forest-500 shrink-0 mt-0.5" />
              Informations publiques et informations de vérification sont toujours séparées.
            </li>
            <li class="flex items-start gap-2.5 text-sm text-forest-700/80">
              <IconTab name="check" class="h-4 w-4 text-forest-500 shrink-0 mt-0.5" />
              Aucune donnée sensible (CNI, téléphone, adresse) n'apparaît publiquement.
            </li>
            <li class="flex items-start gap-2.5 text-sm text-forest-700/80">
              <IconTab name="check" class="h-4 w-4 text-forest-500 shrink-0 mt-0.5" />
              Chaque déclaration suit un statut clair, du dépôt jusqu'à la récupération.
            </li>
          </ul>
          <NuxtLink to="/securite" class="btn-outline">
            En savoir plus sur la sécurité <IconTab name="arrow" class="h-4 w-4" />
          </NuxtLink>
        </div>

        <div class="grid sm:grid-cols-2 gap-4">
          <div v-for="s in securiteInfos" :key="s.titre" class="card p-5">
            <span class="flex h-9 w-9 items-center justify-center rounded-full bg-forest-50 text-forest-600 mb-3">
              <IconTab :name="s.icon" class="h-4 w-4" />
            </span>
            <h3 class="font-display font-semibold text-sm mb-1.5">{{ s.titre }}</h3>
            <p class="text-xs text-forest-500 leading-relaxed">{{ s.texte }}</p>
          </div>
        </div>
      </div>
    </section>

    <!-- RÉSEAU DE PARTENAIRES (2 colonnes) -->
    <section class="section py-8 md:py-10 bg-ivoire-100 mx-4 sm:mx-5 lg:mx-8">
      <div class="container-app grid lg:grid-cols-2 gap-8 lg:gap-12 items-center">
        <div class="order-2 lg:order-1 grid grid-cols-2 sm:grid-cols-3 gap-3">
          <div v-for="p in partenairesTypes" :key="p.nom" class="card p-4 flex flex-col items-center text-center gap-2">
            <span class="flex h-10 w-10 items-center justify-center rounded-full bg-savane-50 text-savane-600">
              <IconTab :name="p.icon" class="h-4.5 w-4.5" />
            </span>
            <span class="text-xs font-semibold text-forest-700">{{ p.nom }}</span>
          </div>
        </div>
        <div class="order-1 lg:order-2">
          <span class="badge-orange mb-4"><IconTab name="handshake" class="h-3.5 w-3.5" /> Réseau en expansion</span>
          <h2 class="text-2xl md:text-3xl font-bold mb-3">Un réseau de partenaires partout en Côte d'Ivoire</h2>
          <p class="text-forest-700/70 mb-6 max-w-md">
            Commissariats, mairies, écoles, gares, centres commerciaux... RETROUVA s'associe à des
            structures locales pour permettre le dépôt et la remise sécurisée des objets trouvés,
            au plus près de chez vous.
          </p>
          <NuxtLink to="/points-relais" class="btn-primary">
            Voir les points relais <IconTab name="arrow" class="h-4 w-4" />
          </NuxtLink>
        </div>
      </div>
    </section>

    <!-- TÉMOIGNAGES -->
    <section class="section py-7 md:py-9">
      <div class="container-app">
        <span class="eyebrow">Ils nous font confiance</span>
        <div class="section-divider my-3"></div>
        <h2 class="text-2xl md:text-3xl font-bold mb-6">Des retrouvailles chaque semaine</h2>

        <div class="grid sm:grid-cols-3 gap-5">
          <div v-for="t in temoignages" :key="t.nom" class="card p-6">
            <div class="flex gap-0.5 mb-4 text-savane-500">
              <IconTab v-for="n in 5" :key="n" name="check" class="h-3.5 w-3.5" />
            </div>
            <p class="text-sm text-forest-700/80 leading-relaxed mb-5">« {{ t.citation }} »</p>
            <div class="flex items-center gap-3">
              <span class="flex h-9 w-9 items-center justify-center rounded-full bg-forest-800 text-white text-xs font-display font-bold">
                {{ t.initiales }}
              </span>
              <div>
                <p class="text-sm font-semibold text-forest-800">{{ t.nom }}</p>
                <p class="text-xs text-forest-400">{{ t.ville }}</p>
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>

    <!-- FAQ RAPIDE (2 colonnes) -->
    <section class="section py-7 md:py-9">
      <div class="container-app grid lg:grid-cols-3 gap-8">
        <div class="lg:col-span-1">
          <span class="eyebrow">Questions fréquentes</span>
          <div class="section-divider my-3"></div>
          <h2 class="text-2xl md:text-3xl font-bold mb-3">Vous avez des questions ?</h2>
          <p class="text-forest-700/70 mb-5">
            Un aperçu des questions les plus posées par les utilisateurs de RETROUVA.
          </p>
          <NuxtLink to="/faq" class="btn-outline">
            Voir toute la FAQ <IconTab name="arrow" class="h-4 w-4" />
          </NuxtLink>
        </div>
        <div class="lg:col-span-2 space-y-3">
          <details v-for="f in faqApercu" :key="f.q" class="card p-5 group">
            <summary class="flex items-center justify-between gap-3 cursor-pointer font-display font-semibold text-sm text-forest-800 list-none">
              {{ f.q }}
              <IconTab name="plus" class="h-4 w-4 text-forest-400 shrink-0 transition-transform group-open:rotate-45" />
            </summary>
            <p class="text-sm text-forest-500 leading-relaxed mt-3">{{ f.r }}</p>
          </details>
        </div>
      </div>
    </section>

    <!-- CTA FINAL -->
    <section class="section pb-8 md:pb-10">
      <div class="container-app bg-brand-gradient p-8 md:p-12 text-center text-white relative overflow-hidden">
        <div class="pointer-events-none absolute -top-16 -right-16 h-56 w-56 rounded-full bg-white/10 blur-3xl"></div>
        <h2 class="text-2xl md:text-3xl font-bold text-white mb-3 relative">Prêt à retrouver ce que vous avez perdu&nbsp;?</h2>
        <p class="text-white/85 mb-7 max-w-md mx-auto relative">
          Déclarez en 2 minutes, gratuitement et en toute sécurité.
        </p>
        <div class="flex flex-wrap gap-3 justify-center relative">
          <NuxtLink to="/perdu" class="btn bg-white text-[#0B3D24] hover:bg-ivoire-100"><IconTab name="search" class="h-4 w-4" /> J'ai perdu un objet</NuxtLink>
          <NuxtLink to="/trouve" class="btn bg-forest-800 text-white hover:bg-forest-700"><IconTab name="plus" class="h-4 w-4" /> J'ai trouvé un objet</NuxtLink>
        </div>
      </div>
    </section>
  </div>
</template>

<style scoped>
/* Anneaux qui tournent lentement en sens opposés, façon halo 3D */
.hero-ring {
  position: absolute;
  border-radius: 9999px;
  border: 1.5px solid rgba(245, 144, 30, 0.25);
}
.hero-ring-1 {
  width: 92%;
  height: 92%;
  border-color: rgba(245, 144, 30, 0.28);
  animation: spin-slow 22s linear infinite;
}
.hero-ring-2 {
  width: 70%;
  height: 70%;
  border-color: rgba(11, 61, 36, 0.22);
  border-style: dashed;
  animation: spin-slow-reverse 30s linear infinite;
}

/* Orbes en dégradé qui flottent doucement, donnant une profondeur "3D" */
.hero-orb {
  position: absolute;
  border-radius: 9999px;
  filter: blur(28px);
  opacity: 0.55;
}
.hero-orb-a {
  width: 38%;
  height: 38%;
  top: 6%;
  left: 8%;
  background: radial-gradient(circle, #F5901E 0%, transparent 70%);
  animation: float-a 9s ease-in-out infinite;
}
.hero-orb-b {
  width: 32%;
  height: 32%;
  bottom: 8%;
  right: 6%;
  background: radial-gradient(circle, #0B3D24 0%, transparent 70%);
  animation: float-b 11s ease-in-out infinite;
}
.hero-orb-c {
  width: 24%;
  height: 24%;
  bottom: 18%;
  left: 12%;
  background: radial-gradient(circle, #5FA574 0%, transparent 70%);
  animation: float-a 13s ease-in-out infinite reverse;
}

/* Le logo flotte très légèrement pour renforcer l'effet de profondeur */
.hero-float {
  animation: float-logo 6s ease-in-out infinite;
}

@keyframes spin-slow {
  from { transform: rotate(0deg); }
  to { transform: rotate(360deg); }
}
@keyframes spin-slow-reverse {
  from { transform: rotate(0deg); }
  to { transform: rotate(-360deg); }
}
@keyframes float-a {
  0%, 100% { transform: translate(0, 0) scale(1); }
  50% { transform: translate(10px, -14px) scale(1.08); }
}
@keyframes float-b {
  0%, 100% { transform: translate(0, 0) scale(1); }
  50% { transform: translate(-12px, 10px) scale(1.05); }
}
@keyframes float-logo {
  0%, 100% { transform: translateY(0); }
  50% { transform: translateY(-10px); }
}

@media (prefers-reduced-motion: reduce) {
  .hero-ring, .hero-orb, .hero-float {
    animation: none;
  }
}
</style>
