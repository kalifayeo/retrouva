<script setup>
const supabase = useSupabase()
const configured = useSupabaseConfigured()
const route = useRoute()
const runtimeConfig = useRuntimeConfig()

// Solution de repli : si Supabase n'est pas configuré ou si l'admin n'a
// encore rien renseigné dans /admin/dons, on affiche exactement les
// mêmes numéros qu'avant (aucune régression visuelle).
const moyensParDefaut = [
  { id: 'defaut-orange', nom: 'Orange Money', type: 'mobile_money', numero: '+225 07 97 67 65 45', instructions: 'Composez #144# puis suivez les instructions pour envoyer vers ce numéro.', icone: 'card' },
  { id: 'defaut-mtn', nom: 'MTN Mobile Money', type: 'mobile_money', numero: '+225 05 46 22 97 78', instructions: 'Composez *133# puis suivez les instructions pour envoyer vers ce numéro.', icone: 'card' },
  { id: 'defaut-wave', nom: 'Wave', type: 'wave', numero: '+225 07 97 67 65 45', instructions: "Ouvrez l'application Wave, choisissez \"Envoyer\" puis saisissez ce numéro.", icone: 'card' }
]

const moyens = ref(moyensParDefaut)
const chargement = ref(true)

const chargerMoyens = async () => {
  if (!configured || !supabase) { chargement.value = false; return }
  const { data } = await supabase
    .from('payment_methods')
    .select('*')
    .eq('actif', true)
    .order('ordre', { ascending: true })
  if (data && data.length) moyens.value = data
  chargement.value = false
}
onMounted(chargerMoyens)

// ---------------------------------------------------------------------
// FORMULAIRE DE DON
// ---------------------------------------------------------------------
const montantsRapides = [1000, 2000, 5000, 10000, 25000]
const etape = ref('choix') // 'choix' -> 'confirmation'
const form = reactive({
  montant: 2000, montantPerso: '', nom: '', telephone: '', email: '', message: '',
  typeDonateur: 'particulier', raisonSociale: ''
})
const methodeSelectionnee = ref(null)
const enregistrement = ref(false)
const erreur = ref('')
const referenceGeneree = ref('')
const copie = ref(false)

const montantFinal = computed(() => {
  const perso = parseInt(form.montantPerso, 10)
  return form.montantPerso && !Number.isNaN(perso) && perso > 0 ? perso : form.montant
})

const choisirMontant = (m) => { form.montant = m; form.montantPerso = '' }

const genererReference = () => 'DON-' + Date.now().toString(36).toUpperCase() + '-' + Math.floor(Math.random() * 900 + 100)

const validerChoix = async () => {
  erreur.value = ''
  if (!methodeSelectionnee.value) { erreur.value = 'Choisissez un moyen de paiement.'; return }
  if (!montantFinal.value || montantFinal.value <= 0) { erreur.value = 'Indiquez un montant valide.'; return }

  referenceGeneree.value = genererReference()

  // La création passe désormais par une route serveur (server/api/dons/
  // creer.post.js), qui valide et applique une limite de fréquence par IP
  // — l'ancienne insertion directe depuis le navigateur n'existe plus,
  // pour ne plus dépendre d'une policy RLS ouverte à tous.
  enregistrement.value = true
  try {
    // Si un visiteur est connecté, son don est relié à son compte (jeton
    // envoyé au serveur, jamais son id directement) pour apparaître dans
    // son historique sur /mes-dons — facultatif, un don reste possible
    // sans être connecté.
    let jeton = ''
    if (configured && supabase) {
      const { data: sessionData } = await supabase.auth.getSession()
      jeton = sessionData?.session?.access_token || ''
    }

    await $fetch('/api/dons/creer', {
      method: 'POST',
      headers: jeton ? { Authorization: `Bearer ${jeton}` } : undefined,
      body: {
        reference: referenceGeneree.value,
        montant: montantFinal.value,
        nom: form.nom.trim(),
        telephone: form.telephone.trim(),
        email: form.email.trim(),
        message: form.message.trim(),
        typeDonateur: form.typeDonateur,
        raisonSociale: form.raisonSociale.trim(),
        paymentMethodId: methodeSelectionnee.value.id
      }
    })
  } catch (e) {
    // On n'empêche jamais le donateur de voir les instructions de paiement
    // même si l'enregistrement échoue (ex. hors-ligne, ou limite de
    // fréquence atteinte) : le don physique (transfert mobile money) reste
    // possible indépendamment de la base. En revanche, sans ligne en base,
    // le paiement en ligne (Orange/MTN/Wave) ne pourra pas être vérifié
    // automatiquement plus tard — d'où l'avertissement ci-dessous.
    if (e?.statusCode === 429) {
      erreur.value = e?.data?.statusMessage || 'Trop de tentatives récentes — réessayez dans quelques minutes.'
      enregistrement.value = false
      return
    }
  } finally {
    enregistrement.value = false
  }

  etape.value = 'confirmation'
}

const recommencer = () => {
  etape.value = 'choix'
  methodeSelectionnee.value = null
  form.nom = ''; form.telephone = ''; form.message = ''
  erreur.value = ''
}

const copierNumero = async () => {
  if (!methodeSelectionnee.value) return
  try {
    await navigator.clipboard.writeText(methodeSelectionnee.value.numero)
    copie.value = true
    setTimeout(() => { copie.value = false }, 2000)
  } catch (e) { /* presse-papiers indisponible : le numéro reste affiché à l'écran */ }
}

// ---------------------------------------------------------------------
// OUVERTURE DE L'APPLICATION DE PAIEMENT
// ---------------------------------------------------------------------
// Redirige vers l'application mobile correspondante :
//  - Wave       -> tentative d'ouverture de l'app installée (lien "wave://"),
//                  avec repli automatique vers la page de téléchargement
//                  si l'app n'est pas présente sur l'appareil.
//  - Orange/MTN -> ouverture du clavier d'appel avec le code USSD du
//                  service Mobile Money prérempli, prêt à composer.
// Ceci reste "au mieux" : la réussite dépend des apps installées sur
// l'appareil du visiteur. Les instructions manuelles restent affichées
// juste en dessous en repli, comme avant.
const lienWaveApp = 'wave://'
const lienWaveRepli = 'https://wave.com/en/download/'

const nomMethodeMinuscule = computed(() => (methodeSelectionnee.value?.nom || '').toLowerCase())
const estOrangeMoney = computed(() => nomMethodeMinuscule.value.includes('orange'))
const estMtnMoney = computed(() => nomMethodeMinuscule.value.includes('mtn'))

const libelleOuverture = computed(() => {
  if (!methodeSelectionnee.value) return ''
  if (methodeSelectionnee.value.type === 'wave') return "Ouvrir l'application Wave"
  if (estOrangeMoney.value || estMtnMoney.value) return `Composer le code ${methodeSelectionnee.value.nom}`
  return ''
})

const ouvrirApplicationPaiement = () => {
  if (!methodeSelectionnee.value || typeof window === 'undefined') return

  if (methodeSelectionnee.value.type === 'wave') {
    const depart = Date.now()
    window.location.href = lienWaveApp
    // Si après ~1,2s la page est toujours là (l'app Wave n'a pas pris le
    // relais), on considère qu'elle n'est pas installée et on ouvre la
    // page de téléchargement à la place.
    setTimeout(() => {
      if (Date.now() - depart < 2500 && !document.hidden) window.location.href = lienWaveRepli
    }, 1200)
    return
  }

  if (estOrangeMoney.value) { window.location.href = 'tel:%23144%23'; return }
  if (estMtnMoney.value) { window.location.href = 'tel:*133%23'; return }
}

// ---------------------------------------------------------------------
// PAIEMENT EN LIGNE (API Orange Money / MTN Mobile Money / Wave)
// ---------------------------------------------------------------------
// Indicateurs exposés par nuxt.config.js (aucune clé, juste des booléens) :
// un bouton "Payer en ligne" n'apparaît que si le serveur a bien les
// identifiants du fournisseur correspondant. Sans cela, le parcours manuel
// ci-dessus (numéro à copier / USSD) reste la seule option — exactement
// comme avant l'ajout de ces API.
const paiementsActifs = runtimeConfig.public.paiementsActifs || {}
const paiementEnLigneDisponible = computed(() => {
  if (!methodeSelectionnee.value) return false
  if (methodeSelectionnee.value.type === 'wave') return !!paiementsActifs.wave
  if (estOrangeMoney.value) return !!paiementsActifs.orange
  if (estMtnMoney.value) return !!paiementsActifs.mtn
  return false
})

const telephonePaiement = ref('')
const paiementEnCours = ref(false)
const erreurPaiement = ref('')
const statutMtn = ref('') // '' | 'attente' | 'succes' | 'echec'

const payerEnLigne = async () => {
  erreurPaiement.value = ''
  statutMtn.value = ''
  if (!methodeSelectionnee.value || !montantFinal.value) return

  const necessiteTelephone = estOrangeMoney.value || estMtnMoney.value
  if (necessiteTelephone) {
    // Numéro ivoirien : 10 chiffres locaux (ex. 0797676545) ou format
    // international +225XXXXXXXXXX / 225XXXXXXXXXX. On valide le format
    // ici pour ne jamais envoyer un numéro manifestement invalide à
    // l'API du fournisseur (qui facturerait un appel pour rien).
    const chiffres = telephonePaiement.value.replace(/\D/g, '')
    const formatValide = /^(225)?0?[0-9]{9,10}$/.test(chiffres) && chiffres.length >= 10
    if (!telephonePaiement.value.trim() || !formatValide) {
      erreurPaiement.value = 'Indiquez un numéro Mobile Money ivoirien valide (ex. 07 97 67 65 45).'
      return
    }
  }

  paiementEnCours.value = true
  try {
    if (methodeSelectionnee.value.type === 'wave') {
      const { url } = await $fetch('/api/dons/wave', {
        method: 'POST',
        body: { montant: montantFinal.value, reference: referenceGeneree.value }
      })
      window.location.href = url
      return
    }

    if (estOrangeMoney.value) {
      const { url } = await $fetch('/api/dons/orange', {
        method: 'POST',
        body: { montant: montantFinal.value, reference: referenceGeneree.value, telephone: telephonePaiement.value }
      })
      window.location.href = url
      return
    }

    if (estMtnMoney.value) {
      const { referenceId } = await $fetch('/api/dons/mtn', {
        method: 'POST',
        body: { montant: montantFinal.value, reference: referenceGeneree.value, telephone: telephonePaiement.value }
      })
      suivreStatutMtn(referenceId)
      return
    }
  } catch (e) {
    erreurPaiement.value = e?.data?.statusMessage
      || "Le paiement en ligne n'est pas disponible pour le moment — utilisez les instructions manuelles ci-dessous."
    paiementEnCours.value = false
  }
}

// MTN envoie un prompt sur le téléphone plutôt qu'une redirection : on
// interroge périodiquement le statut jusqu'à validation, refus, ou un délai
// maximal de 90 secondes.
const suivreStatutMtn = (referenceId) => {
  statutMtn.value = 'attente'
  const debut = Date.now()

  const verifier = async () => {
    try {
      const { statut } = await $fetch('/api/dons/mtn-statut', { params: { ref: referenceId } })
      if (statut === 'SUCCESSFUL') { statutMtn.value = 'succes'; paiementEnCours.value = false; return }
      if (statut === 'FAILED') {
        statutMtn.value = 'echec'
        paiementEnCours.value = false
        erreurPaiement.value = 'Le paiement a été refusé ou annulé sur le téléphone.'
        return
      }
    } catch (e) { /* on retente jusqu'au délai maximal ci-dessous */ }

    if (Date.now() - debut < 90000) {
      setTimeout(verifier, 4000)
    } else {
      statutMtn.value = 'echec'
      paiementEnCours.value = false
      erreurPaiement.value = 'Délai dépassé — vérifiez sur votre téléphone si une demande MTN Mobile Money est en attente.'
    }
  }
  verifier()
}

// ---------------------------------------------------------------------
// RETOUR DEPUIS WAVE / ORANGE APRÈS PAIEMENT (success_url / return_url)
// ---------------------------------------------------------------------
// On ne se fie JAMAIS à "?paiement=succes" seul : n'importe qui peut
// taper cette URL à la main sans avoir rien payé. On revérifie le VRAI
// statut auprès de notre serveur (GET /api/dons/verifier), qui lui-même
// ne fait confiance qu'aux webhooks vérifiés par signature/appel officiel
// (voir server/api/dons/orange-notification.post.js et wave-webhook.post.js).
// Tant que la vérification n'a pas répondu, on n'affiche rien : mieux
// vaut un léger délai qu'un faux message de succès.
const statutVerification = ref('verification') // 'verification' | 'confirme' | 'en_attente' | 'aucun'

const verifierPaiementRetour = async () => {
  const referenceRetour = String(route.query.ref || '')
  if (!(route.query.paiement === 'succes' && referenceRetour)) { statutVerification.value = 'aucun'; return }

  try {
    const resultat = await $fetch('/api/dons/verifier', { params: { ref: referenceRetour } })
    statutVerification.value = resultat.statut === 'confirme' ? 'confirme' : 'en_attente'
  } catch (e) {
    statutVerification.value = 'en_attente'
  }
}
onMounted(verifierPaiementRetour)

const paiementConfirme = computed(() => statutVerification.value === 'confirme')
const paiementEnVerification = computed(() => route.query.paiement === 'succes' && statutVerification.value === 'verification')
const paiementNonEncoreConfirme = computed(() => route.query.paiement === 'succes' && statutVerification.value === 'en_attente')
</script>

<template>
  <div class="section py-14 md:py-20">
    <div class="container-app max-w-xl mx-auto">
      <div class="text-center">
        <span class="badge-orange mb-5"><IconTab name="handshake" class="h-3.5 w-3.5" /> Soutenir RETROUVA</span>
        <h1 class="text-2xl md:text-3xl font-bold mb-3">Faire un don</h1>
        <p class="text-forest-700/70 mb-10 max-w-md mx-auto">
          RETROUVA est un service gratuit pour toute la communauté. Vos dons aident à couvrir les
          coûts d'hébergement, de SMS et de modération, et à garder la plateforme gratuite pour tous.
        </p>
      </div>

      <!-- Retour depuis Wave ou Orange Money : le vrai statut est revérifié
           côté serveur (voir verifierPaiementRetour) avant d'afficher quoi
           que ce soit — on ne se fie jamais au seul paramètre d'URL. -->
      <div v-if="paiementEnVerification" class="card p-5 mb-6 text-center">
        <IconTab name="loader" class="h-5 w-5 animate-spin text-savane-600 mx-auto mb-3" />
        <p class="text-sm text-forest-700/70">Vérification de votre paiement en cours…</p>
      </div>

      <div v-else-if="paiementConfirme" class="card p-5 mb-6 border-2 border-forest-500 bg-forest-50/60 text-center">
        <span class="mx-auto flex h-11 w-11 items-center justify-center rounded-full bg-forest-800 text-white mb-3">
          <IconTab name="check" class="h-5 w-5" />
        </span>
        <h2 class="font-display font-bold mb-1">Paiement reçu — merci beaucoup ! 🙏</h2>
        <p class="text-sm text-forest-700/70">Votre don a bien été transmis. Toute l'équipe RETROUVA vous remercie.</p>
      </div>

      <div v-else-if="paiementNonEncoreConfirme" class="card p-5 mb-6 border-2 border-savane-300 bg-savane-50/50 text-center">
        <IconTab name="loader" class="h-5 w-5 text-savane-600 mx-auto mb-3" />
        <h2 class="font-display font-bold mb-1">Paiement pas encore confirmé</h2>
        <p class="text-sm text-forest-700/70">
          Si vous venez de valider le paiement, la confirmation peut prendre quelques instants —
          actualisez cette page dans une minute. Votre référence reste consultable ci-dessous si besoin.
        </p>
      </div>

      <!-- ÉTAPE 1 : choix du montant + du moyen de paiement -->
      <div v-if="etape === 'choix'" class="text-left">
        <div class="card p-5 mb-4">
          <h2 class="font-display font-semibold text-sm mb-3">Montant du don (FCFA)</h2>
          <div class="grid grid-cols-3 sm:grid-cols-5 gap-2 mb-3">
            <button
              v-for="m in montantsRapides" :key="m" type="button"
              class="rounded-xl border-2 py-2.5 text-sm font-semibold transition-all duration-150 tap-target"
              :class="form.montant === m && !form.montantPerso
                ? 'border-savane-500 bg-savane-50 text-savane-700'
                : 'border-forest-100 text-forest-700 hover:border-forest-200'"
              @click="choisirMontant(m)"
            >
              {{ m.toLocaleString('fr-FR') }}
            </button>
          </div>
          <input
            v-model="form.montantPerso" type="number" min="100" step="100"
            class="input-field" placeholder="Ou un autre montant…"
          />
        </div>

        <div class="card p-5 mb-4">
          <h2 class="font-display font-semibold text-sm mb-3">Moyen de paiement</h2>
          <p v-if="chargement" class="text-sm text-forest-500">Chargement…</p>
          <div v-else class="space-y-2.5">
            <button
              v-for="m in moyens" :key="m.id" type="button"
              class="w-full flex items-center gap-4 rounded-xl border-2 p-4 text-left transition-all duration-150 tap-target"
              :class="methodeSelectionnee?.id === m.id ? 'border-savane-500 bg-savane-50' : 'border-forest-100 hover:border-forest-200'"
              @click="methodeSelectionnee = m"
            >
              <span class="flex h-11 w-11 items-center justify-center rounded-full bg-forest-50 text-forest-700 shrink-0">
                <IconTab :name="m.icone || 'card'" class="h-5 w-5" />
              </span>
              <div class="min-w-0 flex-1">
                <h3 class="font-display font-semibold">{{ m.nom }}</h3>
                <p class="text-sm text-forest-700/70 truncate">{{ m.numero }}</p>
              </div>
              <span
                class="flex h-5 w-5 shrink-0 items-center justify-center rounded-full border-2"
                :class="methodeSelectionnee?.id === m.id ? 'border-savane-500 bg-savane-500' : 'border-forest-200'"
              >
                <IconTab v-if="methodeSelectionnee?.id === m.id" name="check" class="h-3 w-3 text-white" />
              </span>
            </button>
          </div>
        </div>

        <div class="card p-5 mb-4">
          <h2 class="font-display font-semibold text-sm mb-3">Vos coordonnées <span class="font-normal text-forest-400 normal-case">(facultatif)</span></h2>

          <div class="flex gap-2 mb-3">
            <button
              type="button" class="flex-1 rounded-xl border-2 py-2 text-sm font-semibold transition-all duration-150"
              :class="form.typeDonateur === 'particulier' ? 'border-savane-500 bg-savane-50 text-savane-700' : 'border-forest-100 text-forest-700'"
              @click="form.typeDonateur = 'particulier'"
            >Particulier</button>
            <button
              type="button" class="flex-1 rounded-xl border-2 py-2 text-sm font-semibold transition-all duration-150"
              :class="form.typeDonateur === 'entreprise' ? 'border-savane-500 bg-savane-50 text-savane-700' : 'border-forest-100 text-forest-700'"
              @click="form.typeDonateur = 'entreprise'"
            >Entreprise / partenaire</button>
          </div>

          <input
            v-if="form.typeDonateur === 'entreprise'"
            v-model="form.raisonSociale" class="input-field mb-3" placeholder="Raison sociale de l'entreprise"
          />

          <div class="grid sm:grid-cols-2 gap-3 mb-3">
            <input v-model="form.nom" class="input-field" :placeholder="form.typeDonateur === 'entreprise' ? 'Nom du contact' : 'Votre nom'" />
            <input v-model="form.telephone" type="tel" class="input-field" placeholder="Votre téléphone" />
          </div>
          <input v-model="form.email" type="email" class="input-field mb-3" placeholder="Votre e-mail (pour recevoir un reçu)" />
          <textarea v-model="form.message" rows="2" class="input-field resize-none" placeholder="Un petit mot (facultatif)"></textarea>
          <p class="text-xs text-forest-400 mt-2">
            L'e-mail sert uniquement à vous envoyer un reçu une fois le don confirmé par notre équipe — il n'est
            jamais partagé. Pour une attestation de don destinée à votre comptabilité, indiquez le mode
            "Entreprise / partenaire" ci-dessus.
          </p>
        </div>

        <p v-if="erreur" class="text-sm text-red-600 mb-3">{{ erreur }}</p>
        <button class="btn-accent w-full !py-3.5" :disabled="enregistrement" @click="validerChoix">
          {{ enregistrement ? 'Un instant…' : `Faire ce don de ${montantFinal.toLocaleString('fr-FR')} FCFA` }}
          <IconTab name="arrow" class="h-4 w-4" />
        </button>
      </div>

      <!-- ÉTAPE 2 : instructions de paiement -->
      <div v-else class="text-left">
        <div class="card p-6 mb-4 text-center">
          <span class="mx-auto flex h-14 w-14 items-center justify-center rounded-full bg-forest-50 text-forest-700 mb-4">
            <IconTab name="check" class="h-6 w-6" />
          </span>
          <h2 class="font-display font-bold text-lg mb-1">Merci pour votre générosité 🙏</h2>
          <p class="text-sm text-forest-700/70">
            Suivez les instructions ci-dessous avec {{ methodeSelectionnee?.nom }} pour finaliser votre don de
            <span class="font-semibold text-forest-800">{{ montantFinal.toLocaleString('fr-FR') }} FCFA</span>.
          </p>
        </div>

        <button
          v-if="libelleOuverture"
          class="btn-accent w-full !py-3.5 mb-4"
          type="button"
          @click="ouvrirApplicationPaiement"
        >
          <IconTab name="arrow" class="h-4 w-4" /> {{ libelleOuverture }}
        </button>

        <!-- PAIEMENT EN LIGNE (API) : n'apparaît que si le serveur a les
             identifiants du fournisseur correspondant (voir .env). Le
             parcours manuel plus bas reste toujours disponible en repli. -->
        <div v-if="paiementEnLigneDisponible" class="card p-5 mb-4 border-2 border-savane-200">
          <h2 class="font-display font-semibold text-sm mb-3 flex items-center gap-2">
            <IconTab name="card" class="h-4 w-4 text-savane-600" /> Payer directement en ligne
          </h2>

          <template v-if="statutMtn !== 'succes'">
            <input
              v-if="estOrangeMoney || estMtnMoney"
              v-model="telephonePaiement"
              type="tel"
              class="input-field mb-3"
              placeholder="Numéro Mobile Money à débiter (ex. 0797676545)"
              :disabled="paiementEnCours"
            />

            <p v-if="statutMtn === 'attente'" class="flex items-center gap-2 text-sm text-forest-700/80 mb-3">
              <IconTab name="loader" class="h-4 w-4 animate-spin text-savane-600 shrink-0" />
              Une demande a été envoyée sur votre téléphone — validez-la avec votre code secret Mobile Money.
            </p>

            <p v-if="erreurPaiement" class="text-sm text-red-600 mb-3">{{ erreurPaiement }}</p>

            <button
              class="btn-accent w-full !py-3"
              type="button"
              :disabled="paiementEnCours"
              @click="payerEnLigne"
            >
              <IconTab v-if="paiementEnCours" name="loader" class="h-4 w-4 animate-spin" />
              <IconTab v-else name="arrow" class="h-4 w-4" />
              {{ paiementEnCours ? 'Un instant…' : `Payer ${montantFinal.toLocaleString('fr-FR')} FCFA maintenant` }}
            </button>
          </template>

          <div v-else class="flex items-center gap-2 text-sm font-semibold text-forest-700">
            <IconTab name="check" class="h-4 w-4 text-forest-600" /> Paiement confirmé, merci !
          </div>

          <p class="text-xs text-forest-400 mt-3 text-center">— ou suivez les instructions manuelles ci-dessous —</p>
        </div>

        <div class="card p-5 mb-4">
          <p class="label-field mb-1">Numéro à utiliser</p>
          <div class="flex items-center gap-3">
            <p class="flex-1 font-display font-bold text-lg text-forest-800 tracking-wide">{{ methodeSelectionnee?.numero }}</p>
            <button class="btn-outline !px-4 !py-2 text-xs shrink-0" @click="copierNumero">
              <IconTab name="copy" class="h-3.5 w-3.5" /> {{ copie ? 'Copié !' : 'Copier' }}
            </button>
          </div>
          <p v-if="methodeSelectionnee?.instructions" class="text-sm text-forest-700/70 mt-4 pt-4 border-t border-forest-50">
            {{ methodeSelectionnee.instructions }}
          </p>
        </div>

        <div class="card p-5 mb-6 bg-forest-50/40">
          <p class="text-xs text-forest-500 mb-1">Référence de votre don (à conserver)</p>
          <p class="font-display font-bold text-forest-800">{{ referenceGeneree }}</p>
        </div>

        <p class="text-xs text-forest-400 mb-6 text-center">
          Une fois le transfert effectué, notre équipe confirme la réception sous peu — inutile d'envoyer
          de capture d'écran, votre référence suffit si vous nous contactez.
          <span v-if="form.email"> Un reçu vous sera envoyé par e-mail dès la confirmation.</span>
        </p>

        <button class="btn-outline w-full" @click="recommencer">Faire un autre don</button>
      </div>
    </div>
  </div>
</template>
