<script setup>
const supabase = useSupabase()
const configured = useSupabaseConfigured()

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
const form = reactive({ montant: 2000, montantPerso: '', nom: '', telephone: '', message: '' })
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

  if (configured && supabase) {
    enregistrement.value = true
    try {
      await supabase.from('donations').insert({
        reference: referenceGeneree.value,
        nom_donateur: form.nom.trim() || null,
        telephone_donateur: form.telephone.trim() || null,
        montant: montantFinal.value,
        payment_method_id: typeof methodeSelectionnee.value.id === 'string' && methodeSelectionnee.value.id.startsWith('defaut-') ? null : methodeSelectionnee.value.id,
        message: form.message.trim() || null
      })
    } catch (e) {
      // On n'empêche jamais le donateur de voir les instructions de paiement
      // même si l'enregistrement échoue (ex. hors-ligne) : le don physique
      // (transfert mobile money) reste possible indépendamment de la base.
    } finally {
      enregistrement.value = false
    }
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
          <div class="grid sm:grid-cols-2 gap-3 mb-3">
            <input v-model="form.nom" class="input-field" placeholder="Votre nom" />
            <input v-model="form.telephone" type="tel" class="input-field" placeholder="Votre téléphone" />
          </div>
          <textarea v-model="form.message" rows="2" class="input-field resize-none" placeholder="Un petit mot (facultatif)"></textarea>
          <p class="text-xs text-forest-400 mt-2">
            Utile uniquement si notre équipe doit vous recontacter pour confirmer la réception du don.
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
        </p>

        <button class="btn-outline w-full" @click="recommencer">Faire un autre don</button>
      </div>
    </div>
  </div>
</template>
