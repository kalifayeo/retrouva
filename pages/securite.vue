<script setup>
const points = [
  { title: 'Aucune donnée sensible publiée', text: 'Les numéros complets de documents ou de cartes ne sont jamais affichés publiquement.', icon: 'shield' },
  { title: 'Collecte minimale', text: 'Nous ne demandons que les informations strictement nécessaires à la mise en relation.', icon: 'card' },
  { title: 'Vérification avant restitution', text: 'Chaque restitution passe par une étape de vérification du propriétaire.', icon: 'check' },
  { title: 'Contrôle d’accès strict', text: 'Les accès aux données personnelles sont limités et journalisés (audit logs).', icon: 'clock' },
  { title: 'Lutte contre la fraude', text: 'Système de signalement et de modération pour détecter les comportements abusifs.', icon: 'bell' },
  { title: 'Cartes bancaires', text: 'Parcours spécifique évitant toute collecte inutile de données financières.', icon: 'card' }
]
</script>

<template>
  <div class="section py-10 md:py-16">
    <div class="container-app max-w-3xl">
      <span class="badge-green mb-4"><IconTab name="shield" class="h-3.5 w-3.5" /> Confiance &amp; confidentialité</span>
      <h1 class="text-2xl md:text-3xl font-bold mb-3">Votre sécurité, notre priorité</h1>
      <p class="text-forest-700/70 mb-10 max-w-xl">
        RETROUVA est construit comme un réseau de confiance. Voici les principes qui protègent vos
        informations à chaque étape.
      </p>

      <div class="grid sm:grid-cols-2 gap-5">
        <div v-for="p in points" :key="p.title" class="card p-5">
          <span class="flex h-10 w-10 items-center justify-center rounded-full bg-forest-50 text-forest-700 mb-3">
            <IconTab :name="p.icon" class="h-5 w-5" />
          </span>
          <h3 class="font-display font-semibold mb-1">{{ p.title }}</h3>
          <p class="text-sm text-forest-700/70 leading-relaxed">{{ p.text }}</p>
        </div>
      </div>
    </div>
  </div>
</template>
