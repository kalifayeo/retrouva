<script setup>
// Page autonome (sans header/footer) — même contenu que l'overlay affiché
// automatiquement par app.vue quand la connexion est coupée. Utile comme
// lien direct (ex. dans un email, un raccourci, ou une future page d'accueil
// PWA hors-ligne).
definePageMeta({ layout: false })

useHead({ title: 'Hors ligne — RETROUVA' })
</script>

<template>
  <HorsLigneContenu />
</template>
