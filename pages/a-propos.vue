<script setup>
useHead({
  title: 'À propos — RETROUVA',
  meta: [
    { name: 'description', content: "Découvrez la mission de RETROUVA, plateforme ivoirienne qui aide à retrouver, connecter et restituer les objets et documents perdus." }
  ]
})

// Chiffres clés : mêmes données publiques que la page d'accueil (fonction
// RPC Supabase `public_stats`), avec un repli silencieux si Supabase n'est
// pas configuré ou hors ligne — la page reste utile sans ces chiffres.
const supabase = useSupabase()
const configured = useSupabaseConfigured()
const stats = ref(null)
onMounted(async () => {
  if (!configured || !supabase) return
  try {
    const { data } = await supabase.rpc('public_stats')
    if (data) stats.value = data
  } catch (e) { /* chiffres facultatifs : la page reste utile sans eux */ }
})

const valeurs = [
  { titre: 'Confiance avant tout', texte: "Chaque mise en relation passe par une vérification, pour éviter les fausses déclarations et protéger les propriétaires légitimes.", icon: 'shield' },
  { titre: 'Gratuit pour tous', texte: "Déclarer, rechercher ou restituer un objet ne coûte rien. RETROUVA vit grâce aux dons et à des partenariats locaux.", icon: 'handshake' },
  { titre: "Pensé pour la Côte d'Ivoire", texte: "Réseau de points relais, numéros locaux, USSD Mobile Money : conçu pour être utile partout, avec ou sans smartphone récent.", icon: 'pin' },
  { titre: "Simplicité d'abord", texte: "Quelques minutes suffisent pour déclarer un objet perdu ou trouvé, sans jargon ni démarche compliquée.", icon: 'check' }
]

const etapes = [
  { titre: 'Une perte, un signalement', texte: "Un objet ou document est perdu ou trouvé quelque part en Côte d'Ivoire." },
  { titre: 'La déclaration', texte: "La personne le déclare sur RETROUVA en quelques minutes, avec photo et lieu si possible." },
  { titre: 'Le rapprochement', texte: "Notre système compare les déclarations « perdu » et « trouvé » pour repérer les correspondances possibles." },
  { titre: 'La restitution', texte: "Les deux parties sont mises en relation en toute sécurité, en direct ou via un point relais partenaire." }
]
</script>

<template>
  <div class="section py-14 md:py-20">
    <div class="container-app max-w-3xl">
      <div class="text-center mb-14">
        <span class="badge-green mb-5"><IconTab name="info" class="h-3.5 w-3.5" /> À propos de RETROUVA</span>
        <h1 class="text-2xl md:text-3xl font-bold mb-4">Trouver. Connecter. Restituer.</h1>
        <p class="text-forest-700/70 max-w-xl mx-auto leading-relaxed">
          RETROUVA est la plateforme ivoirienne dédiée à la restitution des objets et documents
          importants perdus : pièces d'identité, cartes, téléphones, portefeuilles, clés… Notre
          mission est simple : redonner à chacun ce qui lui appartient, le plus vite possible.
        </p>
      </div>

      <!-- Chiffres clés -->
      <div v-if="stats" class="grid grid-cols-2 sm:grid-cols-4 gap-4 mb-16">
        <div class="card p-4 text-center">
          <div class="text-2xl font-display font-extrabold text-forest-800">{{ stats.trouves ?? '—' }}</div>
          <p class="text-xs text-forest-500 mt-1">Objets trouvés</p>
        </div>
        <div class="card p-4 text-center">
          <div class="text-2xl font-display font-extrabold text-forest-800">{{ stats.restitutions ?? '—' }}</div>
          <p class="text-xs text-forest-500 mt-1">Restitutions</p>
        </div>
        <div class="card p-4 text-center">
          <div class="text-2xl font-display font-extrabold text-forest-800">{{ stats.utilisateurs ?? '—' }}</div>
          <p class="text-xs text-forest-500 mt-1">Membres</p>
        </div>
        <div class="card p-4 text-center">
          <div class="text-2xl font-display font-extrabold text-forest-800">{{ stats.villes ?? '—' }}</div>
          <p class="text-xs text-forest-500 mt-1">Villes couvertes</p>
        </div>
      </div>

      <!-- Notre mission -->
      <div class="mb-16">
        <p class="eyebrow mb-2">Pourquoi RETROUVA</p>
        <h2 class="text-xl font-bold mb-4">Un problème que nous vivons tous</h2>
        <p class="text-forest-700/70 leading-relaxed mb-3">
          Perdre sa carte nationale d'identité, son passeport ou son téléphone en Côte d'Ivoire
          relève souvent du parcours du combattant : petites annonces éparpillées, groupes
          WhatsApp, bouche-à-oreille… avec peu de garanties de récupérer son bien un jour.
        </p>
        <p class="text-forest-700/70 leading-relaxed">
          RETROUVA centralise ces déclarations sur une seule plateforme, sécurisée et gratuite,
          pour que ceux qui trouvent un objet puissent facilement le signaler, et que ceux qui
          l'ont perdu puissent le retrouver rapidement — en toute confiance.
        </p>
      </div>

      <!-- Comment ça marche, résumé -->
      <div class="mb-16">
        <p class="eyebrow mb-2">Le principe</p>
        <h2 class="text-xl font-bold mb-6">De la perte à la restitution</h2>
        <div class="space-y-4">
          <div v-for="(e, i) in etapes" :key="e.titre" class="flex gap-4">
            <span class="flex h-9 w-9 shrink-0 items-center justify-center rounded-full bg-forest-800 text-white font-display font-bold text-sm">{{ i + 1 }}</span>
            <div>
              <h3 class="font-display font-semibold mb-0.5">{{ e.titre }}</h3>
              <p class="text-sm text-forest-700/70 leading-relaxed">{{ e.texte }}</p>
            </div>
          </div>
        </div>
        <NuxtLink to="/comment-ca-marche" class="inline-flex items-center gap-1.5 text-sm font-semibold text-savane-600 mt-5">
          Voir le détail complet <IconTab name="arrow" class="h-3.5 w-3.5" />
        </NuxtLink>
      </div>

      <!-- Nos valeurs -->
      <div class="mb-16">
        <p class="eyebrow mb-2">Nos valeurs</p>
        <h2 class="text-xl font-bold mb-6">Ce qui guide RETROUVA</h2>
        <div class="grid sm:grid-cols-2 gap-5">
          <div v-for="v in valeurs" :key="v.titre" class="card p-5">
            <span class="flex h-10 w-10 items-center justify-center rounded-full bg-forest-50 text-forest-700 mb-3">
              <IconTab :name="v.icon" class="h-5 w-5" />
            </span>
            <h3 class="font-display font-semibold mb-1">{{ v.titre }}</h3>
            <p class="text-sm text-forest-700/70 leading-relaxed">{{ v.texte }}</p>
          </div>
        </div>
      </div>

      <!-- Appel à l'action -->
      <div class="card p-8 text-center bg-forest-800 border-forest-800">
        <h2 class="font-display font-bold text-lg text-white mb-2">Envie de nous aider à grandir ?</h2>
        <p class="text-forest-100/80 text-sm mb-6 max-w-md mx-auto">
          RETROUVA reste gratuit pour tous grâce à ses donateurs et à ses partenaires locaux.
          Chaque geste compte.
        </p>
        <div class="flex flex-col sm:flex-row items-center justify-center gap-3">
          <NuxtLink to="/don" class="btn-accent w-full sm:w-auto"><IconTab name="handshake" class="h-4 w-4" /> Faire un don</NuxtLink>
          <NuxtLink to="/partenaire" class="btn-outline !border-white !text-white hover:!bg-white hover:!text-forest-800 w-full sm:w-auto">Devenir partenaire</NuxtLink>
        </div>
      </div>
    </div>
  </div>
</template>
