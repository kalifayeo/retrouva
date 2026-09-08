<script setup>
useHead({ title: 'Politique de confidentialité — RETROUVA' })

const sections = [
  {
    titre: '1. Qui sommes-nous',
    contenu: [
      "RETROUVA (« nous », « le service ») est une plateforme ivoirienne de mise en relation entre personnes ayant perdu un objet ou un document et personnes en ayant retrouvé un, afin d'en faciliter la restitution.",
      "Éditeur du site : [Raison sociale à compléter], [forme juridique à compléter], immatriculée au RCCM sous le numéro [à compléter], dont le siège est à [adresse à compléter], Côte d'Ivoire. Voir aussi nos mentions légales."
    ]
  },
  {
    titre: '2. Données que nous collectons',
    contenu: [
      "Compte : nom affiché, adresse e-mail, numéro de téléphone, ville et commune.",
      "Déclarations d'objets perdus ou trouvés : catégorie, description, lieu, date, photos, et — pour les documents d'identité — des informations complémentaires protégées servant uniquement à la vérification du propriétaire (jamais publiées ni visibles par le trouveur).",
      "Messagerie : échanges entre un déclarant et un trouveur au sujet d'un objet.",
      "Données techniques : journal des connexions et actions sensibles (audit), à des fins de sécurité et de lutte contre la fraude."
    ]
  },
  {
    titre: '3. Pourquoi nous les utilisons',
    contenu: [
      "Mettre en relation les personnes qui perdent et celles qui trouvent un objet ou un document.",
      "Vérifier l'identité du propriétaire avant toute restitution, afin d'éviter les fraudes.",
      "Assurer la sécurité du service : détection des signalements abusifs, tenue de journaux d'audit sur les accès aux données sensibles.",
      "Vous informer par e-mail, SMS ou notification interne de l'avancement de vos démarches (correspondance trouvée, message reçu, etc.).",
      "Améliorer le service et son contenu (statistiques agrégées et anonymisées)."
    ]
  },
  {
    titre: '4. Qui peut voir vos informations',
    contenu: [
      "Les informations sensibles (numéros complets de documents, cartes) ne sont jamais publiées ni visibles par un autre utilisateur ; elles ne servent qu'à la vérification automatique au moment de la restitution.",
      "Un trouveur et un déclarant ne voient les coordonnées de contact de l'autre que lorsqu'une correspondance est confirmée entre leurs deux déclarations.",
      "Les partenaires (points relais, agents relais) n'ont accès qu'aux informations strictement nécessaires à la remise physique d'un objet.",
      "Notre équipe (administrateurs, modérateurs) peut consulter les données en cas de signalement, de litige ou d'obligation légale ; ces accès sont journalisés."
    ]
  },
  {
    titre: '5. Durée de conservation',
    contenu: [
      "Vos données de compte sont conservées tant que votre compte est actif.",
      "Les déclarations résolues (objet restitué) ou closes sont conservées pour une durée raisonnable à des fins de preuve et de lutte contre la fraude, puis supprimées ou anonymisées.",
      "En cas de suppression de votre compte, vos données personnelles et déclarations liées sont supprimées, sous réserve des données que nous devons conserver pour répondre à une obligation légale."
    ]
  },
  {
    titre: '6. Vos droits',
    contenu: [
      "Conformément à la loi ivoirienne n° 2013-450 du 19 juin 2013 relative à la protection des données à caractère personnel, ainsi qu'aux standards internationaux en la matière, vous disposez d'un droit d'accès, de rectification, d'opposition et de suppression de vos données.",
      "Vous pouvez modifier vos informations directement depuis votre profil, ou supprimer votre compte et toutes les données associées depuis Profil → Paramètres du compte.",
      "Pour toute autre demande relative à vos données, contactez-nous à l'adresse indiquée dans nos mentions légales."
    ]
  },
  {
    titre: '7. Sécurité',
    contenu: [
      "Les mots de passe ne sont jamais stockés en clair. Les échanges avec le site sont chiffrés (HTTPS). L'accès aux données sensibles est restreint et journalisé.",
      "Aucun système n'étant infaillible, nous vous invitons à ne jamais transmettre d'informations sensibles (mot de passe, code de vérification) à une personne se présentant comme membre de RETROUVA en dehors du site."
    ]
  },
  {
    titre: '8. Cookies',
    contenu: [
      "Le détail des cookies utilisés et la gestion de vos préférences se trouvent sur notre page dédiée : politique de cookies."
    ]
  },
  {
    titre: '9. Modifications',
    contenu: [
      "Cette politique peut être mise à jour pour refléter une évolution du service ou de la réglementation. La date de dernière mise à jour figure ci-dessous."
    ]
  }
]
</script>

<template>
  <div class="section py-10 md:py-16">
    <div class="container-app max-w-3xl">
      <span class="eyebrow">Vie privée</span>
      <div class="section-divider my-3"></div>
      <h1 class="text-2xl md:text-3xl font-bold mb-2">Politique de confidentialité</h1>
      <p class="text-sm text-forest-500 mb-8">Dernière mise à jour : [à compléter lors de la mise en ligne]</p>

      <div class="space-y-8">
        <div v-for="s in sections" :key="s.titre">
          <h2 class="font-display font-semibold text-lg mb-2.5">{{ s.titre }}</h2>
          <p v-for="(p, i) in s.contenu" :key="i" class="text-sm text-forest-700/75 leading-relaxed mb-2">
            <template v-if="s.titre === '8. Cookies'">
              Le détail des cookies utilisés et la gestion de vos préférences se trouvent sur notre
              <NuxtLink to="/cookies" class="text-savane-600 font-semibold">page dédiée</NuxtLink>.
            </template>
            <template v-else>{{ p }}</template>
          </p>
        </div>
      </div>

      <div class="card p-5 mt-10 bg-savane-50">
        <p class="text-sm text-forest-700/80 leading-relaxed">
          <strong>Une question sur vos données ?</strong> Contactez-nous via la page
          <NuxtLink to="/signalement" class="text-savane-600 font-semibold">Signaler un problème</NuxtLink>
          ou les coordonnées indiquées dans nos
          <NuxtLink to="/mentions-legales" class="text-savane-600 font-semibold">mentions légales</NuxtLink>.
        </p>
      </div>
    </div>
  </div>
</template>
