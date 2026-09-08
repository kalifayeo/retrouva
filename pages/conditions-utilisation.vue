<script setup>
useHead({ title: "Conditions générales d'utilisation — RETROUVA" })

const sections = [
  {
    titre: '1. Objet',
    contenu: "Les présentes conditions générales d'utilisation (CGU) régissent l'accès et l'utilisation de la plateforme RETROUVA, service de mise en relation entre personnes ayant perdu un objet ou un document et personnes en ayant retrouvé un, en Côte d'Ivoire. En créant un compte ou en utilisant le site, vous acceptez sans réserve les présentes CGU."
  },
  {
    titre: '2. Description du service',
    contenu: "RETROUVA permet de déclarer un objet perdu ou trouvé, de rechercher une correspondance, d'échanger via une messagerie interne, puis d'organiser une restitution après vérification du propriétaire. RETROUVA est un intermédiaire de mise en relation : nous ne sommes ni gardien, ni propriétaire, ni assureur des objets déclarés."
  },
  {
    titre: '3. Inscription et compte',
    contenu: "L'inscription est gratuite et réservée aux personnes physiques capables de s'engager juridiquement. Vous vous engagez à fournir des informations exactes et à jour, et à garder confidentiels vos identifiants de connexion. Vous êtes responsable de toute activité effectuée depuis votre compte."
  },
  {
    titre: '4. Engagements de l\'utilisateur',
    contenu: "En utilisant RETROUVA, vous vous engagez à : ne déclarer que des objets ou documents réellement perdus ou trouvés par vous-même ; ne pas usurper l'identité d'un tiers ni prétendre être propriétaire d'un objet qui ne vous appartient pas ; ne publier aucun contenu illicite, diffamatoire, frauduleux ou portant atteinte aux droits d'autrui ; utiliser la messagerie uniquement dans le cadre d'une restitution légitime ; respecter les autres utilisateurs et les équipes RETROUVA."
  },
  {
    titre: '5. Vérification et restitution',
    contenu: "Toute restitution est précédée d'une étape de vérification destinée à s'assurer que la personne qui réclame un objet en est bien le propriétaire. RETROUVA se réserve le droit de suspendre ou d'annuler une mise en relation en cas de doute raisonnable sur la légitimité d'une déclaration. La remise physique de l'objet, en main propre ou via un point relais partenaire, reste sous la responsabilité des utilisateurs concernés."
  },
  {
    titre: '6. Signalement et modération',
    contenu: "Tout comportement frauduleux, abusif ou suspect peut être signalé depuis la page « Signaler un problème ». RETROUVA peut suspendre ou supprimer un compte en cas de violation des présentes CGU, sans préavis en cas d'urgence (fraude avérée, sécurité d'un tiers)."
  },
  {
    titre: '7. Contenus publiés',
    contenu: "Vous restez propriétaire des contenus (photos, descriptions) que vous publiez, et garantissez disposer des droits nécessaires pour le faire. Vous accordez à RETROUVA le droit de les afficher sur la plateforme dans le seul cadre du fonctionnement du service."
  },
  {
    titre: '8. Don et soutien financier',
    contenu: "La fonctionnalité de don est facultative et ne conditionne l'accès à aucune fonctionnalité du service. Aucune passerelle de paiement automatisée n'étant connectée à ce jour, chaque don constitue une intention de versement, confirmée manuellement après réception effective."
  },
  {
    titre: '9. Responsabilité',
    contenu: "RETROUVA met tout en œuvre pour assurer la fiabilité du service, sans garantir l'absence d'erreur, d'interruption ou de correspondance erronée. RETROUVA ne saurait être tenu responsable des préjudices résultant d'une déclaration mensongère faite par un utilisateur, d'un litige entre utilisateurs lors d'une restitution, ou d'une interruption temporaire du service."
  },
  {
    titre: '10. Données personnelles',
    contenu: "Le traitement de vos données personnelles est décrit dans notre politique de confidentialité, qui fait partie intégrante des présentes CGU."
  },
  {
    titre: '11. Modification des CGU',
    contenu: "RETROUVA peut modifier les présentes CGU à tout moment, notamment pour refléter une évolution du service ou de la réglementation applicable. Les utilisateurs seront informés de toute modification substantielle."
  },
  {
    titre: '12. Droit applicable',
    contenu: "Les présentes CGU sont soumises au droit ivoirien. Tout litige relatif à leur interprétation ou leur exécution relève de la compétence des juridictions ivoiriennes, sauf disposition légale contraire."
  }
]
</script>

<template>
  <div class="section py-10 md:py-16">
    <div class="container-app max-w-3xl">
      <span class="eyebrow">Cadre légal</span>
      <div class="section-divider my-3"></div>
      <h1 class="text-2xl md:text-3xl font-bold mb-2">Conditions générales d'utilisation</h1>
      <p class="text-sm text-forest-500 mb-8">Dernière mise à jour : [à compléter lors de la mise en ligne]</p>

      <div class="space-y-8">
        <div v-for="s in sections" :key="s.titre">
          <h2 class="font-display font-semibold text-lg mb-2.5">{{ s.titre }}</h2>
          <p class="text-sm text-forest-700/75 leading-relaxed">{{ s.contenu }}</p>
        </div>
      </div>

      <div class="card p-5 mt-10 bg-savane-50">
        <p class="text-sm text-forest-700/80 leading-relaxed">
          Voir aussi notre
          <NuxtLink to="/politique-de-confidentialite" class="text-savane-600 font-semibold">politique de confidentialité</NuxtLink>,
          notre
          <NuxtLink to="/cookies" class="text-savane-600 font-semibold">politique de cookies</NuxtLink>
          et nos
          <NuxtLink to="/mentions-legales" class="text-savane-600 font-semibold">mentions légales</NuxtLink>.
        </p>
      </div>
    </div>
  </div>
</template>
