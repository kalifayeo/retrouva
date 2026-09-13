<script setup>
useHead({ title: 'Politique de cookies — RETROUVA' })

const { reinitialiser } = useCookieConsent()

const gerer = () => {
  // Efface le choix enregistré : la bannière réapparaît immédiatement
  // pour permettre à l'utilisateur de changer d'avis.
  reinitialiser()
  window.scrollTo({ top: 0, behavior: 'smooth' })
}

const cookies = [
  {
    nom: 'retrouva_theme',
    type: 'Nécessaire',
    duree: 'Persistant (jusqu\'à suppression manuelle)',
    finalite: 'Mémorise votre préférence d\'affichage (mode clair ou sombre).'
  },
  {
    nom: 'sb-*-auth-token (Supabase)',
    type: 'Nécessaire',
    duree: 'Session / jusqu\'à déconnexion',
    finalite: 'Maintient votre connexion à votre compte RETROUVA de façon sécurisée.'
  },
  {
    nom: 'retrouva_support_id',
    type: 'Nécessaire',
    duree: 'Persistant',
    finalite: 'Identifie votre fil de discussion avec le support, sans vous identifier personnellement.'
  },
  {
    nom: 'retrouva_cookies_consentement',
    type: 'Nécessaire',
    duree: 'Persistant (jusqu\'à 6 mois recommandé)',
    finalite: 'Mémorise votre choix concernant les cookies, pour ne pas vous redemander à chaque visite.'
  },
  {
    nom: 'retrouva_intro_vue',
    type: 'Confort',
    duree: 'Persistant',
    finalite: 'Évite de réafficher l\'écran de bienvenue une fois qu\'il a été vu ou passé.'
  },
  {
    nom: 'retrouva_intro_video_vue',
    type: 'Confort',
    duree: 'Persistant',
    finalite: 'Évite de rejouer la vidéo de présentation à chaque visite.'
  },
  {
    nom: 'retrouva_popup_vu',
    type: 'Confort',
    duree: 'Session (fermé à la fermeture du navigateur)',
    finalite: 'Évite d\'afficher plusieurs fois la même pop-up d\'information pendant une visite.'
  }
]
</script>

<template>
  <div class="section py-10 md:py-16">
    <div class="container-app max-w-3xl">
      <span class="eyebrow">Vie privée</span>
      <div class="section-divider my-3"></div>
      <h1 class="text-2xl md:text-3xl font-bold mb-4">Politique de cookies</h1>
      <p class="text-forest-700/70 mb-8 leading-relaxed">
        Cette page explique ce qu'est un cookie, ceux utilisés par RETROUVA et comment gérer vos
        préférences. Pour tout ce qui concerne vos données personnelles, consultez également notre
        <NuxtLink to="/politique-de-confidentialite" class="text-savane-600 font-semibold">politique de confidentialité</NuxtLink>.
      </p>

      <div class="card p-5 sm:p-6 mb-8">
        <h2 class="font-display font-semibold mb-2">Qu'est-ce qu'un cookie ?</h2>
        <p class="text-sm text-forest-700/75 leading-relaxed">
          Un cookie est un petit fichier déposé sur votre appareil lors de votre visite d'un site
          web. Il permet au site de se souvenir de certaines informations (connexion, préférences)
          d'une visite à l'autre. RETROUVA utilise aussi des équivalents techniques
          (<code class="font-mono text-xs">localStorage</code>, <code class="font-mono text-xs">sessionStorage</code>)
          fonctionnant selon le même principe.
        </p>
      </div>

      <div class="grid sm:grid-cols-2 gap-5 mb-10">
        <div class="card p-5">
          <span class="badge-green mb-3"><IconTab name="shield" class="h-3.5 w-3.5" /> Nécessaires</span>
          <p class="text-sm text-forest-700/75 leading-relaxed">
            Indispensables au fonctionnement du site (connexion, sécurité, préférence de thème).
            Ils ne peuvent pas être désactivés et ne nécessitent pas votre consentement.
          </p>
        </div>
        <div class="card p-5">
          <span class="badge-orange mb-3"><IconTab name="bell" class="h-3.5 w-3.5" /> Confort</span>
          <p class="text-sm text-forest-700/75 leading-relaxed">
            Améliorent votre expérience (pop-up d'information, vidéo et écran de bienvenue).
            Activés uniquement avec votre accord — vous pouvez les refuser à tout moment.
          </p>
        </div>
      </div>

      <h2 class="font-display font-semibold text-lg mb-4">Détail des cookies utilisés</h2>
      <div class="card overflow-hidden mb-10">
        <div class="overflow-x-auto">
          <table class="w-full text-sm">
            <thead class="bg-forest-50 text-forest-700 text-xs uppercase tracking-wide">
              <tr>
                <th class="text-left px-4 py-3 font-semibold">Nom</th>
                <th class="text-left px-4 py-3 font-semibold">Type</th>
                <th class="text-left px-4 py-3 font-semibold">Durée</th>
                <th class="text-left px-4 py-3 font-semibold">Finalité</th>
              </tr>
            </thead>
            <tbody class="divide-y divide-forest-50">
              <tr v-for="c in cookies" :key="c.nom">
                <td class="px-4 py-3 font-mono text-xs align-top whitespace-nowrap">{{ c.nom }}</td>
                <td class="px-4 py-3 align-top whitespace-nowrap">
                  <span :class="c.type === 'Nécessaire' ? 'badge-green' : 'badge-orange'">{{ c.type }}</span>
                </td>
                <td class="px-4 py-3 align-top text-forest-700/70 whitespace-nowrap">{{ c.duree }}</td>
                <td class="px-4 py-3 align-top text-forest-700/70">{{ c.finalite }}</td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>

      <div class="card p-5 sm:p-6 mb-10">
        <h2 class="font-display font-semibold mb-2">RETROUVA n'utilise aucun cookie publicitaire ou de mesure d'audience tiers</h2>
        <p class="text-sm text-forest-700/75 leading-relaxed">
          À ce jour, aucun outil d'analyse (Google Analytics, Meta Pixel, etc.) ni régie
          publicitaire tierce n'est intégré au site. Si cela venait à changer, cette page et le
          bandeau de consentement seraient mis à jour en conséquence.
        </p>
      </div>

      <div class="card p-6 text-center">
        <h2 class="font-display font-semibold mb-2">Gérer mes préférences</h2>
        <p class="text-sm text-forest-700/70 mb-5 max-w-md mx-auto">
          Vous pouvez revenir sur votre choix à tout moment. Le bandeau de consentement
          réapparaîtra pour vous permettre de le modifier.
        </p>
        <button class="btn-primary" @click="gerer">
          <IconTab name="check" class="h-4 w-4" /> Modifier mes préférences de cookies
        </button>
      </div>
    </div>
  </div>
</template>
