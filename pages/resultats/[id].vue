<script setup>
definePageMeta({ middleware: 'auth' })

const route = useRoute()
const { objectTypes } = useObjectTypes()
const { user } = useAuth()
const supabase = useSupabase()

const item = ref(null)
const loading = ref(true)
const erreur = ref('')
const envoiEnCours = ref(false)
const secondesEcoulees = ref(0)
let minuteur = null

const typeInfo = (id) => objectTypes.find(t => t.id === id) || { label: id, image: '' }

const charger = async () => {
  loading.value = true
  erreur.value = ''
  secondesEcoulees.value = 0
  if (minuteur) clearInterval(minuteur)
  minuteur = setInterval(() => { secondesEcoulees.value++ }, 1000)

  if (!supabase || !user.value) {
    loading.value = false
    clearInterval(minuteur)
    if (!user.value) erreur.value = "Vous n'êtes pas connecté."
    if (!supabase) erreur.value = "Supabase n'est pas configuré (fichier .env manquant)."
    return
  }

  try {
    const { data, error } = await avecDelai(supabase
      .from('matches')
      .select(`
        id, score, details,
        lost_report:lost_reports!inner(id, user_id, object_type_id, criteres_verification, statut),
        found_report:found_reports(id, user_id, ville, commune, date_trouvaille, object_type_id)
      `)
      .eq('id', route.params.id)
      .eq('lost_report.user_id', user.value.id)
      .eq('masque', false)
      .maybeSingle(), 8000)

    if (error) {
      console.error('Erreur chargement correspondance :', error)
      erreur.value = "Une erreur est survenue lors du chargement (" + error.message + ")."
    } else if (!data) {
      erreur.value = "Cette correspondance n'existe pas ou ne vous appartient pas."
    } else {
      item.value = data
    }
  } catch (e) {
    console.error('Erreur inattendue :', e)
    erreur.value = e.message || "Une erreur inattendue est survenue. Vérifiez la console (F12) pour le détail."
  } finally {
    loading.value = false
    clearInterval(minuteur)
  }
}

const criteres = computed(() => {
  if (!item.value) return []
  const d = item.value.details || {}
  const liste = [
    { label: 'Type de document', ok: !!d.type_identique },
    { label: 'Zone géographique (ville)', ok: !!d.ville_identique },
    { label: 'Commune', ok: !!d.commune_identique },
    { label: 'Période de perte proche', ok: (d.ecart_jours ?? 999) <= 14 }
  ]
  if (typeof d.description_similaire !== 'undefined') {
    liste.push({ label: 'Description similaire', ok: !!d.description_similaire })
  }
  return liste
})

onMounted(charger)

// Ouvre (ou crée) la conversation liée à cette correspondance, avec un
// premier message automatique, et déclenche une vraie demande de
// vérification (verification_requests) reprenant les éléments privés
// renseignés à la déclaration — le trouveur devra les confirmer avant
// toute mise en relation complète.
const demanderVerification = async () => {
  envoiEnCours.value = true

  const { data: demandeExistante } = await supabase
    .from('verification_requests')
    .select('id')
    .eq('match_id', item.value.id)
    .eq('demandeur_id', user.value.id)
    .limit(1)

  if (!demandeExistante?.length) {
    const criteres = item.value.lost_report.criteres_verification
    const aDesCriteres = Array.isArray(criteres) && criteres.length > 0

    await supabase.from('verification_requests').insert({
      match_id: item.value.id,
      demandeur_id: user.value.id,
      niveau_confiance: item.value.score >= 85 ? 'eleve' : item.value.score >= 60 ? 'moyen' : 'faible',
      reponses: aDesCriteres ? criteres : []
    })

    if (item.value.lost_report.statut === 'active' || item.value.lost_report.statut === 'correspondance') {
      await supabase.from('lost_reports').update({ statut: 'en_verification' }).eq('id', item.value.lost_report.id)
    }
  }

  const { data: existants } = await supabase
    .from('messages')
    .select('id')
    .eq('match_id', item.value.id)
    .limit(1)

  if (!existants?.length) {
    await supabase.from('messages').insert({
      match_id: item.value.id,
      expediteur_id: user.value.id,
      destinataire_id: item.value.found_report.user_id,
      contenu: "Bonjour, je pense que cet objet trouvé pourrait être le mien. J'ai envoyé une demande de vérification avec les éléments qui permettent de le confirmer."
    })
  }
  navigateTo(`/messagerie/${item.value.id}`)
}
</script>

<template>
  <div class="section py-8 md:py-12">
    <div class="container-app max-w-4xl">
      <NuxtLink to="/resultats" class="text-sm text-forest-500 flex items-center gap-1 mb-6">
        <IconTab name="arrow" class="h-4 w-4 rotate-180" /> Retour aux résultats
      </NuxtLink>

      <div v-if="loading" class="text-sm text-forest-500">
        Chargement… ({{ secondesEcoulees }}s — bascule automatique sur une erreur après 8s)
      </div>
      <div v-else-if="erreur" class="text-center py-10">
        <p class="text-sm text-red-600 mb-4 whitespace-pre-line">{{ erreur }}</p>
        <button class="btn-outline" @click="charger">Réessayer</button>
      </div>

      <template v-else-if="item">
        <div class="grid lg:grid-cols-3 gap-6">
          <!-- Colonne gauche : détail de la correspondance -->
          <div class="lg:col-span-2">
            <div class="card overflow-hidden mb-6">
              <div class="flex items-center gap-4 p-6 border-b border-forest-50">
                <span class="flex h-16 w-16 shrink-0 items-center justify-center overflow-hidden rounded-2xl bg-ivoire-100">
                  <img
                    v-if="typeInfo(item.found_report.object_type_id).image"
                    :src="typeInfo(item.found_report.object_type_id).image"
                    :alt="typeInfo(item.found_report.object_type_id).label"
                    class="h-full w-full object-cover"
                  />
                  <IconTab v-else name="card" class="h-7 w-7 text-forest-400" />
                </span>
                <div class="flex-1 min-w-0">
                  <h1 class="text-xl font-bold">{{ typeInfo(item.found_report.object_type_id).label }}</h1>
                  <p class="text-sm text-forest-700/70 flex items-center gap-1.5 mt-1">
                    <IconTab name="pin" class="h-3.5 w-3.5" />
                    {{ item.found_report.commune ? `${item.found_report.commune}, ` : '' }}{{ item.found_report.ville }}
                    · {{ new Date(item.found_report.date_trouvaille).toLocaleDateString('fr-FR') }}
                  </p>
                </div>
                <span class="badge-green shrink-0 !text-base !px-4 !py-1.5">{{ item.score }}%</span>
              </div>

              <div class="p-6 space-y-2.5">
                <p class="label-field !mb-3">Détail du score de correspondance</p>
                <div v-for="c in criteres" :key="c.label" class="flex items-center gap-2 text-sm">
                  <span class="flex h-5 w-5 shrink-0 items-center justify-center rounded-full" :class="c.ok ? 'bg-forest-50' : 'bg-ivoire-200'">
                    <IconTab :name="c.ok ? 'check' : 'close'" class="h-3 w-3" :class="c.ok ? 'text-forest-600' : 'text-forest-300'" />
                  </span>
                  <span :class="c.ok ? 'text-forest-800' : 'text-forest-400'">{{ c.label }}</span>
                </div>
              </div>
            </div>

            <div class="rounded-2xl bg-forest-50 p-4 flex gap-3 mb-6">
              <IconTab name="shield" class="h-5 w-5 text-forest-600 shrink-0 mt-0.5" />
              <p class="text-sm text-forest-700">
                Pour votre sécurité, aucune information privée n'est visible ici. La messagerie vous
                permet d'échanger avec la personne qui a trouvé l'objet, afin de vérifier que c'est
                bien le vôtre, sans jamais publier vos données sensibles.
              </p>
            </div>

            <button class="btn-accent w-full" :disabled="envoiEnCours" :class="{ 'opacity-60': envoiEnCours }" @click="demanderVerification">
              {{ envoiEnCours ? 'Ouverture…' : 'Demander une vérification' }}
            </button>
          </div>

          <!-- Colonne droite : ce qui va se passer ensuite -->
          <div class="space-y-5">
            <div class="card p-5">
              <p class="text-[11px] font-bold uppercase tracking-widest text-forest-400 mb-4">Prochaines étapes</p>
              <ol class="space-y-4 text-sm">
                <li class="flex items-start gap-3">
                  <span class="flex h-6 w-6 shrink-0 items-center justify-center rounded-full bg-forest-800 text-white text-xs font-bold">1</span>
                  <span class="text-forest-700">Vous échangez en toute sécurité via la messagerie RETROUVA, sans partager vos coordonnées.</span>
                </li>
                <li class="flex items-start gap-3">
                  <span class="flex h-6 w-6 shrink-0 items-center justify-center rounded-full bg-forest-100 text-forest-600 text-xs font-bold">2</span>
                  <span class="text-forest-500">Vous confirmez des détails que seul le propriétaire peut connaître.</span>
                </li>
                <li class="flex items-start gap-3">
                  <span class="flex h-6 w-6 shrink-0 items-center justify-center rounded-full bg-forest-100 text-forest-600 text-xs font-bold">3</span>
                  <span class="text-forest-500">Vous organisez la remise : en main propre ou via un point relais.</span>
                </li>
              </ol>
            </div>

            <div class="card p-5 bg-forest-800 text-white">
              <p class="flex items-center gap-1.5 text-[11px] font-bold uppercase tracking-widest text-savane-400 mb-3">
                <IconTab name="shield" class="h-3 w-3" /> Rappel important
              </p>
              <p class="text-sm text-forest-100/80 leading-relaxed">
                Un score élevé n'est pas une preuve de propriété. C'est la vérification qui protège
                tout le monde contre les fausses réclamations.
              </p>
            </div>

            <NuxtLink to="/points-relais" class="card-hover p-5 flex items-center gap-3 block">
              <span class="flex h-10 w-10 items-center justify-center rounded-full bg-savane-50 text-savane-600 shrink-0">
                <IconTab name="pin" class="h-5 w-5" />
              </span>
              <div>
                <p class="text-sm font-display font-semibold text-forest-800">Points relais</p>
                <p class="text-xs text-forest-400">Pour une remise sécurisée près de vous</p>
              </div>
            </NuxtLink>
          </div>
        </div>
      </template>
    </div>
  </div>
</template>
