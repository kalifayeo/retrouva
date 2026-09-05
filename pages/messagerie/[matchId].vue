<script setup>
definePageMeta({ middleware: 'auth' })

const route = useRoute()
const { user } = useAuth()
const { objectTypes } = useObjectTypes()
const supabase = useSupabase()

const match = ref(null)
const messages = ref([])
const loading = ref(true)
const erreur = ref('')
const nouveauMessage = ref('')
const envoiEnCours = ref(false)
const zoneMessages = ref(null)

const verifRequest = ref(null)
const restitutionRequest = ref(null)
const restitution = ref(null)
const pickupPoints = ref([])
const pickupPointChoisi = ref('')
const actionEnCours = ref(false)

const labelType = (id) => objectTypes.find(t => t.id === id)?.label || id

const autreParticipant = computed(() => {
  if (!match.value) return null
  return match.value.lost_report.user_id === user.value.id
    ? match.value.found_report.user_id
    : match.value.lost_report.user_id
})

// Rôle de l'utilisateur courant dans cette correspondance
const estProprietaire = computed(() => match.value && match.value.lost_report.user_id === user.value.id)
const estTrouveur = computed(() => match.value && match.value.found_report.user_id === user.value.id)

const scroll = async () => {
  await nextTick()
  if (zoneMessages.value) zoneMessages.value.scrollTop = zoneMessages.value.scrollHeight
}

const chargerVerification = async () => {
  const { data } = await supabase
    .from('verification_requests')
    .select('id, demandeur_id, niveau_confiance, reponses, validee, created_at')
    .eq('match_id', route.params.matchId)
    .order('created_at', { ascending: false })
    .limit(1)
    .maybeSingle()
  verifRequest.value = data || null
}

const chargerRestitution = async () => {
  const { data: rr } = await supabase
    .from('restitution_requests')
    .select('id, pickup_point_id, statut, created_at')
    .eq('match_id', route.params.matchId)
    .order('created_at', { ascending: false })
    .limit(1)
    .maybeSingle()
  restitutionRequest.value = rr || null

  if (rr) {
    const { data: r } = await supabase
      .from('restitutions')
      .select('id, confirmee_par_proprietaire, confirmee_par_trouveur, date_restitution')
      .eq('restitution_request_id', rr.id)
      .maybeSingle()
    restitution.value = r || null
  } else {
    restitution.value = null
  }
}

const chargerPickupPoints = async () => {
  if (!match.value) return
  const { data } = await supabase
    .from('pickup_points')
    .select('id, nom, ville, commune, adresse')
    .eq('ville', match.value.found_report.ville)
    .eq('actif', true)
    .limit(10)
  pickupPoints.value = data || []
}

const charger = async () => {
  loading.value = true
  erreur.value = ''
  if (!supabase || !user.value) { loading.value = false; return }

  try {
    const { data: m, error: erreurMatch } = await avecDelai(supabase
      .from('matches')
      .select(`
        id,
        lost_report:lost_reports(id, user_id, object_type_id),
        found_report:found_reports(id, user_id, ville, commune)
      `)
      .eq('id', route.params.matchId)
      .maybeSingle())

    if (erreurMatch) {
      console.error('Erreur chargement conversation :', erreurMatch)
      erreur.value = "Une erreur est survenue (" + erreurMatch.message + ")."
      return
    }
    if (!m) {
      erreur.value = "Cette conversation n'existe pas ou ne vous appartient pas."
      return
    }
    match.value = m

    const { data: msgs, error: erreurMsgs } = await avecDelai(supabase
      .from('messages')
      .select('id, expediteur_id, destinataire_id, contenu, lu, created_at')
      .eq('match_id', route.params.matchId)
      .order('created_at', { ascending: true }))

    if (erreurMsgs) console.error('Erreur chargement messages :', erreurMsgs)
    messages.value = msgs || []

    await Promise.all([chargerVerification(), chargerRestitution()])
    if (verifRequest.value?.validee === true && !restitutionRequest.value) await chargerPickupPoints()
  } catch (e) {
    console.error('Erreur inattendue :', e)
    erreur.value = e.message || "Une erreur inattendue est survenue. Vérifiez la console (F12) pour le détail."
  } finally {
    loading.value = false
  }

  if (match.value) scroll()

  const nonLus = messages.value.filter(msg => !msg.lu && msg.destinataire_id === user.value.id).map(msg => msg.id)
  if (nonLus.length) {
    await supabase.from('messages').update({ lu: true }).in('id', nonLus)
  }
}

const envoyer = async () => {
  if (!nouveauMessage.value.trim()) return
  envoiEnCours.value = true
  const { data, error } = await supabase.from('messages').insert({
    match_id: route.params.matchId,
    expediteur_id: user.value.id,
    destinataire_id: autreParticipant.value,
    contenu: nouveauMessage.value.trim()
  }).select().single()

  if (!error && data) {
    messages.value.push(data)
    nouveauMessage.value = ''
    scroll()
  }
  envoiEnCours.value = false
}

// Le trouveur confirme ou rejette la demande de vérification du demandeur
const traiterVerification = async (accepter) => {
  actionEnCours.value = true
  const { error } = await supabase
    .from('verification_requests')
    .update({ validee: accepter })
    .eq('id', verifRequest.value.id)

  if (!error) {
    await supabase.from('messages').insert({
      match_id: route.params.matchId,
      expediteur_id: user.value.id,
      destinataire_id: autreParticipant.value,
      contenu: accepter
        ? "✅ J'ai vérifié les éléments fournis : cela correspond bien à l'objet trouvé."
        : "❌ Les éléments fournis ne correspondent pas à l'objet que j'ai trouvé."
    })
    await Promise.all([chargerVerification(), charger()])
  }
  actionEnCours.value = false
}

// Organise la remise (une fois la vérification validée)
const organiserRemise = async (viaPointRelais) => {
  if (viaPointRelais && !pickupPointChoisi.value) return
  actionEnCours.value = true
  const { data, error } = await supabase.from('restitution_requests').insert({
    match_id: route.params.matchId,
    initiee_par: user.value.id,
    pickup_point_id: viaPointRelais ? pickupPointChoisi.value : null
  }).select().single()

  if (!error && data) {
    restitutionRequest.value = data
    await supabase.from('messages').insert({
      match_id: route.params.matchId,
      expediteur_id: user.value.id,
      destinataire_id: autreParticipant.value,
      contenu: viaPointRelais
        ? "📦 J'ai proposé une remise via un point relais. Merci de confirmer une fois l'objet déposé/récupéré."
        : "🤝 J'ai proposé une remise directe. Merci de confirmer une fois l'objet remis/récupéré."
    })
  }
  actionEnCours.value = false
}

const confirmerRestitution = async () => {
  actionEnCours.value = true
  const champ = estProprietaire.value ? 'confirmee_par_proprietaire' : 'confirmee_par_trouveur'

  let res
  if (restitution.value) {
    res = await supabase.from('restitutions').update({ [champ]: true }).eq('id', restitution.value.id).select().single()
  } else {
    res = await supabase.from('restitutions').insert({ restitution_request_id: restitutionRequest.value.id, [champ]: true }).select().single()
  }
  if (!res.error) restitution.value = res.data
  actionEnCours.value = false
}

const pointRelaisNom = (id) => pickupPoints.value.find(p => p.id === id)?.nom || restitutionRequest.value?.pickup_point_id

onMounted(charger)
</script>

<template>
  <div class="section py-6 md:py-10">
    <div class="container-app max-w-3xl">
      <NuxtLink to="/messagerie" class="text-sm text-forest-500 flex items-center gap-1 mb-4">
        <IconTab name="arrow" class="h-4 w-4 rotate-180" /> Retour à la messagerie
      </NuxtLink>

      <p v-if="loading" class="text-sm text-forest-500">Chargement…</p>
      <p v-else-if="erreur" class="text-sm text-red-600">{{ erreur }}</p>

      <template v-else-if="match">
        <div class="grid md:grid-cols-5 gap-5">
          <!-- Conversation -->
          <div class="md:col-span-3">
            <div class="card overflow-hidden flex flex-col" style="height: 60vh;">
              <div class="flex items-center gap-3 px-5 py-4 border-b border-forest-50 shrink-0">
                <span class="flex h-10 w-10 items-center justify-center rounded-full bg-forest-50 text-forest-700">
                  <IconTab name="chat" class="h-5 w-5" />
                </span>
                <div class="min-w-0">
                  <p class="font-display font-semibold text-sm truncate">{{ labelType(match.lost_report.object_type_id) }}</p>
                  <p class="text-xs text-forest-400 truncate">
                    {{ match.found_report.commune ? `${match.found_report.commune}, ` : '' }}{{ match.found_report.ville }}
                  </p>
                </div>
              </div>

              <div ref="zoneMessages" class="flex-1 overflow-y-auto px-5 py-4 space-y-3">
                <div v-if="!messages.length" class="text-center text-sm text-forest-400 py-10">
                  Aucun message pour le moment. Lancez la conversation ci-dessous.
                </div>
                <div
                  v-for="msg in messages"
                  :key="msg.id"
                  class="flex"
                  :class="msg.expediteur_id === user.id ? 'justify-end' : 'justify-start'"
                >
                  <div
                    class="max-w-[85%] rounded-2xl px-4 py-2.5 text-sm"
                    :class="msg.expediteur_id === user.id
                      ? 'bg-forest-800 text-white rounded-br-sm'
                      : 'bg-ivoire-100 text-forest-800 rounded-bl-sm'"
                  >
                    {{ msg.contenu }}
                    <p class="text-[10px] mt-1 opacity-60">
                      {{ new Date(msg.created_at).toLocaleTimeString('fr-FR', { hour: '2-digit', minute: '2-digit' }) }}
                    </p>
                  </div>
                </div>
              </div>

              <form class="flex items-center gap-2 px-4 py-3 border-t border-forest-50 shrink-0" @submit.prevent="envoyer">
                <input
                  v-model="nouveauMessage"
                  type="text"
                  placeholder="Écrire un message…"
                  class="input-field !py-2.5"
                />
                <button type="submit" class="btn-accent !px-4 !py-2.5 shrink-0" :disabled="envoiEnCours">
                  <IconTab name="arrow" class="h-4 w-4" />
                </button>
              </form>
            </div>

            <div class="rounded-2xl bg-forest-50 p-4 flex gap-3 mt-4">
              <IconTab name="shield" class="h-5 w-5 text-forest-600 shrink-0 mt-0.5" />
              <p class="text-sm text-forest-700">
                Ne partagez jamais de numéro complet de document ou d'informations sensibles ici.
                La vérification ci-contre sert justement à confirmer l'identité sans exposer vos données.
              </p>
            </div>
          </div>

          <!-- Colonne droite : vérification + remise -->
          <div class="md:col-span-2 space-y-4">
            <!-- Aucune demande de vérification encore -->
            <div v-if="!verifRequest" class="card p-5">
              <p class="flex items-center gap-1.5 text-[11px] font-bold uppercase tracking-widest text-forest-400 mb-2">
                <IconTab name="clock" class="h-3 w-3" /> Vérification
              </p>
              <p class="text-sm text-forest-500">Aucune demande de vérification n'a encore été envoyée pour cette correspondance.</p>
            </div>

            <!-- En attente de traitement -->
            <div v-else-if="verifRequest.validee === null" class="card p-5">
              <p class="flex items-center gap-1.5 text-[11px] font-bold uppercase tracking-widest text-savane-600 mb-3">
                <IconTab name="shield" class="h-3 w-3" /> 🔐 Vérification en cours
              </p>

              <template v-if="estTrouveur">
                <p class="text-sm text-forest-700 mb-3">
                  Le demandeur affirme être le propriétaire. Comparez ces éléments avec l'objet que
                  vous avez trouvé, sans les confirmer à voix haute avant sa réponse.
                </p>
                <div v-if="verifRequest.reponses?.length" class="space-y-2 mb-4">
                  <div v-for="(r, i) in verifRequest.reponses" :key="i" class="text-sm bg-ivoire-100 rounded-xl px-3 py-2">
                    <span class="text-forest-400 text-xs block">{{ r.label }}</span>
                    <span class="text-forest-800 font-medium">{{ r.valeur }}</span>
                  </div>
                </div>
                <p v-else class="text-xs text-forest-400 italic mb-4">
                  Le demandeur n'a renseigné aucun élément à la déclaration. Demandez-lui de décrire l'objet dans la conversation avant de valider.
                </p>
                <div class="flex gap-2">
                  <button class="btn-accent flex-1 !text-sm" :disabled="actionEnCours" @click="traiterVerification(true)">Confirmer l'identité</button>
                  <button class="btn-outline flex-1 !text-sm !border-red-200 !text-red-500" :disabled="actionEnCours" @click="traiterVerification(false)">Ce n'est pas concordant</button>
                </div>
              </template>
              <template v-else>
                <p class="text-sm text-forest-500">
                  Votre demande a été envoyée avec {{ verifRequest.reponses?.length || 0 }} élément(s)
                  de vérification. En attente de confirmation par la personne qui a trouvé l'objet.
                </p>
              </template>
            </div>

            <!-- Vérification rejetée -->
            <div v-else-if="verifRequest.validee === false" class="card p-5 bg-red-50">
              <p class="flex items-center gap-1.5 text-[11px] font-bold uppercase tracking-widest text-red-500 mb-2">
                ❌ Correspondance rejetée
              </p>
              <p class="text-sm text-red-700">
                Les éléments fournis ne correspondaient pas. RETROUVA continue la recherche pour cet objet.
              </p>
            </div>

            <!-- Vérification validée : organiser / suivre la remise -->
            <template v-else-if="verifRequest.validee === true">
              <div class="card p-5 bg-forest-50">
                <p class="flex items-center gap-1.5 text-[11px] font-bold uppercase tracking-widest text-forest-600 mb-2">
                  ✅ Identité vérifiée
                </p>
                <p class="text-sm text-forest-700">Vous pouvez maintenant organiser la remise de l'objet.</p>
              </div>

              <div v-if="!restitutionRequest" class="card p-5">
                <p class="text-[11px] font-bold uppercase tracking-widest text-forest-400 mb-3">📍 Organiser la remise</p>
                <button class="btn-primary w-full mb-3 !text-sm" :disabled="actionEnCours" @click="organiserRemise(false)">
                  Remise directe entre nous
                </button>
                <div v-if="pickupPoints.length">
                  <label class="label-field">Ou via un point relais</label>
                  <select v-model="pickupPointChoisi" class="input-field !py-2 mb-2">
                    <option value="" disabled>Choisir un point relais</option>
                    <option v-for="p in pickupPoints" :key="p.id" :value="p.id">{{ p.nom }} — {{ p.commune || p.ville }}</option>
                  </select>
                  <button class="btn-outline w-full !text-sm" :disabled="actionEnCours || !pickupPointChoisi" @click="organiserRemise(true)">
                    Déposer/récupérer en point relais
                  </button>
                </div>
              </div>

              <div v-else class="card p-5">
                <p class="text-[11px] font-bold uppercase tracking-widest text-forest-400 mb-3">
                  {{ restitutionRequest.pickup_point_id ? '📦 Remise en point relais' : '🤝 Remise directe' }}
                </p>
                <p v-if="restitutionRequest.pickup_point_id" class="text-sm text-forest-600 mb-3">
                  {{ pointRelaisNom(restitutionRequest.pickup_point_id) }}
                </p>
                <div class="space-y-2 mb-4 text-sm">
                  <p class="flex items-center gap-2" :class="restitution?.confirmee_par_trouveur ? 'text-forest-700' : 'text-forest-400'">
                    <IconTab :name="restitution?.confirmee_par_trouveur ? 'check' : 'clock'" class="h-4 w-4" /> Confirmation du trouveur
                  </p>
                  <p class="flex items-center gap-2" :class="restitution?.confirmee_par_proprietaire ? 'text-forest-700' : 'text-forest-400'">
                    <IconTab :name="restitution?.confirmee_par_proprietaire ? 'check' : 'clock'" class="h-4 w-4" /> Confirmation du propriétaire
                  </p>
                </div>
                <button
                  v-if="(estProprietaire && !restitution?.confirmee_par_proprietaire) || (estTrouveur && !restitution?.confirmee_par_trouveur)"
                  class="btn-accent w-full !text-sm"
                  :disabled="actionEnCours"
                  @click="confirmerRestitution"
                >
                  {{ estProprietaire ? "Confirmer que j'ai récupéré l'objet" : "Confirmer que j'ai remis l'objet" }}
                </button>
                <p v-else class="text-sm text-forest-500 text-center">En attente de la confirmation de l'autre partie.</p>
              </div>
            </template>
          </div>
        </div>
      </template>
    </div>
  </div>
</template>
