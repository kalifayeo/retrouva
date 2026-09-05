<script setup>
const route = useRoute()
const preselectedType = route.query.type || ''
</script>

<template>
  <div class="section py-10 md:py-16">
    <div class="container-app max-w-2xl">
      <h1 class="text-2xl md:text-3xl font-bold mb-2">Que souhaitez-vous déclarer&nbsp;?</h1>
      <p class="text-forest-700/70 mb-8">Choisissez votre situation pour commencer.</p>

      <div class="grid sm:grid-cols-2 gap-5">
        <NuxtLink
          :to="{ path: '/perdu', query: preselectedType ? { type: preselectedType } : {} }"
          class="card-hover p-6 flex flex-col items-start gap-3"
        >
          <span class="flex h-12 w-12 items-center justify-center rounded-full bg-forest-50 text-forest-700">
            <IconTab name="search" class="h-6 w-6" />
          </span>
          <h2 class="font-display font-semibold text-lg">J'ai perdu un objet</h2>
          <p class="text-sm text-forest-700/70">
            Décrivez ce que vous avez perdu et lancez une recherche de correspondances.
          </p>
          <span class="text-savane-500 text-sm font-semibold flex items-center gap-1 mt-2">
            Continuer <IconTab name="arrow" class="h-4 w-4" />
          </span>
        </NuxtLink>

        <NuxtLink
          :to="{ path: '/trouve', query: preselectedType ? { type: preselectedType } : {} }"
          class="card-hover p-6 flex flex-col items-start gap-3"
        >
          <span class="flex h-12 w-12 items-center justify-center rounded-full bg-savane-50 text-savane-600">
            <IconTab name="plus" class="h-6 w-6" />
          </span>
          <h2 class="font-display font-semibold text-lg">J'ai trouvé un objet</h2>
          <p class="text-sm text-forest-700/70">
            Publiez une déclaration pour aider un propriétaire à récupérer son bien.
          </p>
          <span class="text-savane-500 text-sm font-semibold flex items-center gap-1 mt-2">
            Continuer <IconTab name="arrow" class="h-4 w-4" />
          </span>
        </NuxtLink>
      </div>
    </div>
  </div>
</template>
