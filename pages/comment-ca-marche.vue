<script setup>
const parcours = [
  {
    title: 'J’ai perdu un objet',
    icon: 'search',
    steps: [
      'Choisissez le type d’objet perdu',
      'Renseignez la zone et la date approximative',
      'Lancez la recherche automatique',
      'Consultez les correspondances trouvées',
      'Demandez une vérification sécurisée',
      'Récupérez votre bien'
    ]
  },
  {
    title: 'J’ai trouvé un objet',
    icon: 'plus',
    steps: [
      'Choisissez le type d’objet trouvé',
      'Indiquez le lieu et la date',
      'Ajoutez une photo si utile',
      'Les données sensibles sont masquées automatiquement',
      'Publiez la déclaration',
      'Organisez la restitution avec le propriétaire vérifié'
    ]
  }
]
</script>

<template>
  <div class="section py-10 md:py-16">
    <div class="container-app max-w-3xl">
      <span class="eyebrow">Le parcours RETROUVA</span>
      <div class="section-divider my-3"></div>
      <h1 class="text-2xl md:text-3xl font-bold mb-3">Comment ça marche</h1>
      <p class="text-forest-700/70 mb-10">
        RETROUVA repose sur un principe simple : rapprocher automatiquement les déclarations, puis
        vérifier avant de restituer.
      </p>

      <div class="space-y-10">
        <div v-for="p in parcours" :key="p.title">
          <div class="flex items-center gap-3 mb-5">
            <span class="flex h-10 w-10 items-center justify-center rounded-full bg-forest-800 text-white">
              <IconTab :name="p.icon" class="h-5 w-5" />
            </span>
            <h2 class="text-xl font-display font-semibold">{{ p.title }}</h2>
          </div>
          <ol class="space-y-3">
            <li v-for="(s, i) in p.steps" :key="s" class="flex gap-3 items-start">
              <span class="flex h-6 w-6 shrink-0 items-center justify-center rounded-full bg-forest-50 text-forest-700 text-xs font-bold">{{ i + 1 }}</span>
              <span class="text-forest-700 text-sm pt-0.5">{{ s }}</span>
            </li>
          </ol>
        </div>
      </div>
    </div>
  </div>
</template>
