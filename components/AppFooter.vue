<script setup>
const year = new Date().getFullYear()
</script>

<template>
  <footer class="bg-forest-800 text-white mt-24">
    <div class="section container-app py-14 grid gap-10 md:grid-cols-4">
      <div class="md:col-span-2">
        <div class="flex items-center gap-2 mb-4">
          <img src="/logo.png" alt="RETROUVA" class="h-9 w-9 object-contain" />
          <span class="font-display font-extrabold text-lg">
            RETROUV<span class="text-savane-400">A</span>
          </span>
        </div>
        <p class="text-forest-100/80 text-sm max-w-sm leading-relaxed">
          La plateforme ivoirienne qui aide à retrouver, connecter et restituer les objets et
          documents importants perdus en Côte d'Ivoire.
        </p>
        <div class="mt-5 inline-flex items-center gap-2 rounded-full bg-forest-700 px-4 py-2 text-xs font-semibold">
          <span class="flex h-3 w-5 overflow-hidden rounded-sm">
            <span class="flex-1 bg-savane-500"></span>
            <span class="flex-1 bg-white"></span>
            <span class="flex-1 bg-forest-400"></span>
          </span>
          Plateforme <span class="text-savane-400">ivoirienne</span> de retrouvaille d'objets
        </div>
      </div>

      <div>
        <h4 class="font-display font-semibold mb-4 text-sm uppercase tracking-wide text-forest-100/60">
          Découvrir
        </h4>
        <ul class="space-y-2.5 text-sm text-forest-100/85">
          <li><NuxtLink to="/comment-ca-marche" class="hover:text-savane-400">Comment ça marche</NuxtLink></li>
          <li><NuxtLink to="/points-relais" class="hover:text-savane-400">Points relais</NuxtLink></li>
          <li><NuxtLink to="/evenements" class="hover:text-savane-400">Événements</NuxtLink></li>
          <li><NuxtLink to="/securite" class="hover:text-savane-400">Sécurité &amp; confidentialité</NuxtLink></li>
          <li><NuxtLink to="/faq" class="hover:text-savane-400">FAQ</NuxtLink></li>
          <li><NuxtLink to="/don" class="hover:text-savane-400 font-semibold text-savane-400">💛 Faire un don</NuxtLink></li>
        </ul>
      </div>

      <div>
        <h4 class="font-display font-semibold mb-4 text-sm uppercase tracking-wide text-forest-100/60">
          Assistance
        </h4>
        <ul class="space-y-2.5 text-sm text-forest-100/85">
          <li><NuxtLink to="/signalement" class="hover:text-savane-400">Signaler un problème</NuxtLink></li>
          <li><NuxtLink to="/declarer" class="hover:text-savane-400">Déclarer un objet</NuxtLink></li>
          <li><NuxtLink to="/resultats" class="hover:text-savane-400">Rechercher un objet</NuxtLink></li>
        </ul>
      </div>
    </div>

    <div class="border-t border-forest-700">
      <div class="section container-app py-5 text-xs text-forest-100/60 flex flex-col sm:flex-row gap-2 justify-between">
        <span>© {{ year }} RETROUVA — Tous droits réservés.</span>
        <span>Trouver. Connecter. Restituer.</span>
      </div>
    </div>
  </footer>
</template>
