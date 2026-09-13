<script setup>
useHead({ title: 'Mentions légales — RETROUVA' })

const supabase = useSupabase()

// Valeurs par défaut ("à compléter") tant que l'admin n'a pas renseigné le
// champ correspondant depuis /admin/mentions-legales. Rien n'est cassé si
// certains champs restent vides avant la mise en ligne définitive.
const infos = reactive({
  mentions_raison_sociale: '[à compléter]',
  mentions_forme_juridique: '[à compléter — ex. entreprise individuelle, SARL, SA]',
  mentions_rccm: '[à compléter]',
  mentions_ncc: '[à compléter]',
  mentions_siege_social: "[adresse à compléter], Côte d'Ivoire",
  mentions_email: '[à compléter]',
  mentions_telephone: '[à compléter]',
  mentions_directeur_publication: '[nom à compléter]',
  mentions_hebergeur_nom: "[nom de l'hébergeur, ex. Vercel Inc.]",
  mentions_hebergeur_adresse: "[adresse de l'hébergeur]"
})

// La bannière d'avertissement ne s'affiche que tant que les champs
// essentiels n'ont pas été renseignés depuis l'admin — une fois complétés,
// elle disparaît d'elle-même pour ne pas rester visible aux visiteurs.
const nonConfigure = ref(true)

onMounted(async () => {
  if (!supabase) return
  const { data } = await supabase.from('site_settings').select('cle, valeur').in('cle', Object.keys(infos))
  for (const row of data || []) {
    if (row.valeur) infos[row.cle] = row.valeur
  }
  nonConfigure.value = !infos.mentions_raison_sociale || infos.mentions_raison_sociale === '[à compléter]'
})
</script>

<template>
  <div class="section py-10 md:py-16">
    <div class="container-app max-w-3xl">
      <span class="eyebrow">Cadre légal</span>
      <div class="section-divider my-3"></div>
      <h1 class="text-2xl md:text-3xl font-bold mb-8">Mentions légales</h1>

      <div v-if="nonConfigure" class="card p-5 sm:p-6 mb-8 bg-savane-50 border-savane-200">
        <p class="text-sm text-forest-700/80 leading-relaxed">
          <strong>À compléter avant la mise en ligne définitive :</strong> les informations
          ci-dessous doivent être remplacées par les coordonnées réelles de la structure qui
          exploite RETROUVA (personne physique, entreprise individuelle ou société), conformément
          aux exigences légales applicables en Côte d'Ivoire pour tout site accessible au public.
          Modifiable depuis <strong>Administration → Mentions légales</strong>.
        </p>
      </div>

      <div class="space-y-8">
        <div>
          <h2 class="font-display font-semibold text-lg mb-2.5">Éditeur du site</h2>
          <ul class="text-sm text-forest-700/75 leading-relaxed space-y-1">
            <li><strong>Raison sociale / nom :</strong> {{ infos.mentions_raison_sociale }}</li>
            <li><strong>Forme juridique :</strong> {{ infos.mentions_forme_juridique }}</li>
            <li><strong>Numéro RCCM :</strong> {{ infos.mentions_rccm }}</li>
            <li><strong>Numéro de compte contribuable (NCC) :</strong> {{ infos.mentions_ncc }}</li>
            <li><strong>Siège social :</strong> {{ infos.mentions_siege_social }}</li>
            <li><strong>E-mail de contact :</strong> {{ infos.mentions_email }}</li>
            <li><strong>Téléphone :</strong> {{ infos.mentions_telephone }}</li>
            <li><strong>Directeur de la publication :</strong> {{ infos.mentions_directeur_publication }}</li>
          </ul>
        </div>

        <div>
          <h2 class="font-display font-semibold text-lg mb-2.5">Hébergement</h2>
          <p class="text-sm text-forest-700/75 leading-relaxed">
            Le site est hébergé par {{ infos.mentions_hebergeur_nom }}, {{ infos.mentions_hebergeur_adresse }}.
            La base de données et les fichiers utilisateurs sont hébergés par
            Supabase (Supabase Inc.), dont les serveurs peuvent être situés hors de Côte d'Ivoire.
          </p>
        </div>

        <div>
          <h2 class="font-display font-semibold text-lg mb-2.5">Propriété intellectuelle</h2>
          <p class="text-sm text-forest-700/75 leading-relaxed">
            L'ensemble des éléments du site RETROUVA (charte graphique, logo, textes, structure)
            est protégé par le droit de la propriété intellectuelle. Toute reproduction non
            autorisée est interdite. Les photos d'objets publiées par les utilisateurs restent
            la propriété de leurs auteurs respectifs.
          </p>
        </div>

        <div>
          <h2 class="font-display font-semibold text-lg mb-2.5">Médiation et réclamations</h2>
          <p class="text-sm text-forest-700/75 leading-relaxed">
            Pour toute réclamation, contactez-nous via la page
            <NuxtLink to="/signalement" class="text-savane-600 font-semibold">Signaler un problème</NuxtLink>
            ou aux coordonnées ci-dessus.
          </p>
        </div>

        <div>
          <h2 class="font-display font-semibold text-lg mb-2.5">Documents liés</h2>
          <p class="text-sm text-forest-700/75 leading-relaxed">
            Voir également nos
            <NuxtLink to="/conditions-utilisation" class="text-savane-600 font-semibold">conditions générales d'utilisation</NuxtLink>,
            notre
            <NuxtLink to="/politique-de-confidentialite" class="text-savane-600 font-semibold">politique de confidentialité</NuxtLink>
            et notre
            <NuxtLink to="/cookies" class="text-savane-600 font-semibold">politique de cookies</NuxtLink>.
          </p>
        </div>
      </div>
    </div>
  </div>
</template>
