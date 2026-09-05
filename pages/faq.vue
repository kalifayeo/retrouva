<script setup>
const faqs = [
  { q: 'RETROUVA est-il gratuit ?', a: 'Oui, déclarer un objet perdu ou trouvé est entièrement gratuit pour les particuliers.' },
  { q: 'Comment mes données sont-elles protégées ?', a: "Les informations sensibles (numéros de documents, cartes) ne sont jamais publiées. Elles ne servent qu'à la vérification finale entre le trouveur et le propriétaire." },
  { q: 'Comment fonctionne la vérification du propriétaire ?', a: "Le système pose des questions dont les réponses sont comparées aux informations protégées enregistrées. Le trouveur ne voit jamais ces réponses." },
  { q: 'Que se passe-t-il si quelqu’un ment sur la propriété d’un objet ?', a: "Un mécanisme de signalement et de modération permet de détecter et traiter les tentatives frauduleuses." },
  { q: 'Puis-je utiliser RETROUVA hors d’Abidjan ?', a: "Oui, la plateforme couvre progressivement plusieurs villes de Côte d'Ivoire." },
  { q: 'Comment se passe la restitution physique ?', a: "En main propre après vérification, ou via un point relais partenaire selon les zones disponibles." }
]

const open = ref(0)
const toggle = (i) => { open.value = open.value === i ? -1 : i }
</script>

<template>
  <div class="section py-10 md:py-16">
    <div class="container-app max-w-2xl">
      <span class="eyebrow">Besoin d'aide</span>
      <div class="section-divider my-3"></div>
      <h1 class="text-2xl md:text-3xl font-bold mb-8">Questions fréquentes</h1>

      <div class="space-y-3">
        <div v-for="(f, i) in faqs" :key="f.q" class="card overflow-hidden">
          <button class="w-full flex items-center justify-between gap-4 p-5 text-left tap-target" @click="toggle(i)">
            <span class="font-display font-semibold">{{ f.q }}</span>
            <IconTab name="plus" class="h-4 w-4 shrink-0 text-savane-500 transition-transform" :class="{ 'rotate-45': open === i }" />
          </button>
          <div v-if="open === i" class="px-5 pb-5 text-sm text-forest-700/80 leading-relaxed">
            {{ f.a }}
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
