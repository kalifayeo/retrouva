<script setup>
definePageMeta({ middleware: 'auth' })

const { user, profile } = useAuth()
const supabase = useSupabase()
const { objectTypes } = useObjectTypes()
const { infoStatut } = useStatuts()

// ---------------------------------------------------------------------
// STATUT DU COMPTE — affiché dans le bandeau d'accueil (utile surtout
// sur mobile où le rôle n'apparaît nulle part ailleurs pour l'utilisateur).
// ---------------------------------------------------------------------
const rolesInfo = {
  utilisateur: { label: 'Compte standard', icon: 'user' },
  utilisateur_verifie: { label: 'Compte vérifié', icon: 'shield' },
  moderateur: { label: 'Modérateur', icon: 'shield' },
  administrateur: { label: 'Administrateur', icon: 'shield' },
  partenaire: { label: 'Partenaire', icon: 'handshake' },
  agent_relais: { label: 'Agent relais', icon: 'pin' },
  super_administrateur: { label: 'Super administrateur', icon: 'shield' }
}
const statutCompte = computed(() => rolesInfo[profile.value?.role] || { label: 'Compte standard', icon: 'user' })

const compteurs = reactive({ perdus: null, trouves: null, correspondances: null, messages: null, recuperes: null })
const mesPerdus = ref([])
const mesTrouves = ref([])
const mesNotifications = ref([])
const loading = ref(true)

const labelType = (id) => objectTypes.find(t => t.id === id)?.label || id

const charger = async () => {
  loading.value = true
  if (!supabase || !user.value) { loading.value = false; return }

  const [perdus, trouves, correspondances, messages, recuperes, listePerdus, listeTrouves, listeNotifs] = await Promise.all([
    supabase.from('lost_reports').select('id', { count: 'exact', head: true }).eq('user_id', user.value.id),
    supabase.from('found_reports').select('id', { count: 'exact', head: true }).eq('user_id', user.value.id),
    supabase.from('matches').select('id, lost_report:lost_reports!inner(user_id)', { count: 'exact', head: true }).eq('lost_report.user_id', user.value.id),
    supabase.from('messages').select('id', { count: 'exact', head: true }).eq('destinataire_id', user.value.id).eq('lu', false),
    supabase.from('lost_reports').select('id', { count: 'exact', head: true }).eq('user_id', user.value.id).eq('statut', 'restituee'),
    supabase.from('lost_reports').select('id, object_type_id, ville, statut, created_at').eq('user_id', user.value.id).order('created_at', { ascending: false }).limit(3),
    supabase.from('found_reports').select('id, object_type_id, ville, statut, created_at').eq('user_id', user.value.id).order('created_at', { ascending: false }).limit(3),
    supabase.from('notifications').select('id, titre, corps, type, lu, created_at').eq('user_id', user.value.id).order('created_at', { ascending: false }).limit(5)
  ])

  compteurs.perdus = perdus.count ?? 0
  compteurs.trouves = trouves.count ?? 0
  compteurs.correspondances = correspondances.count ?? 0
  compteurs.messages = messages.count ?? 0
  compteurs.recuperes = recuperes.count ?? 0
  mesPerdus.value = listePerdus.data || []
  mesTrouves.value = listeTrouves.data || []
  mesNotifications.value = listeNotifs.data || []
  loading.value = false
}

onMounted(charger)
</script>

<template>
  <div class="pb-12">
    <!-- Bandeau d'accueil -->
    <section class="bg-brand-gradient text-white py-8 px-5 sm:px-8 lg:px-16 mb-8">
      <div class="container-app flex flex-wrap items-center justify-between gap-4">
        <div>
          <h1 class="text-xl sm:text-2xl font-bold text-white">
            Bonjour {{ profile?.nom_affiche || 'à vous' }} 👋
          </h1>
          <p class="text-white/85 text-sm mt-1">Voici un aperçu de votre activité sur RETROUVA.</p>
          <span class="inline-flex items-center gap-1.5 mt-3 rounded-full bg-white/15 px-3 py-1.5 text-xs font-semibold text-white">
            <IconTab :name="statutCompte.icon" class="h-3.5 w-3.5" /> {{ statutCompte.label }}
          </span>
        </div>
        <div class="flex gap-3">
          <NuxtLink to="/perdu" class="btn bg-white text-[#0B3D24] hover:bg-ivoire-100 text-sm">
            <IconTab name="plus" class="h-4 w-4" /> Déclarer une perte
          </NuxtLink>
          <NuxtLink to="/trouve" class="btn bg-forest-800 text-white hover:bg-forest-700 text-sm">
            <IconTab name="plus" class="h-4 w-4" /> Déclarer une trouvaille
          </NuxtLink>
        </div>
      </div>
    </section>

    <div class="section">
      <div class="container-app">
        <p v-if="loading" class="text-sm text-forest-500">Chargement…</p>

        <template v-else>
          <!-- Compteurs -->
          <div class="grid grid-cols-2 lg:grid-cols-5 gap-4 mb-8">
            <NuxtLink to="/mes-recherches" class="card-hover p-5">
              <span class="flex h-10 w-10 items-center justify-center rounded-full bg-savane-50 text-savane-600 mb-3">
                <IconTab name="card" class="h-5 w-5" />
              </span>
              <div class="text-2xl font-display font-extrabold text-forest-800">{{ compteurs.perdus }}</div>
              <div class="text-xs text-forest-500 mt-0.5">Objets perdus</div>
            </NuxtLink>
            <NuxtLink to="/mes-objets-trouves" class="card-hover p-5">
              <span class="flex h-10 w-10 items-center justify-center rounded-full bg-forest-50 text-forest-600 mb-3">
                <IconTab name="search" class="h-5 w-5" />
              </span>
              <div class="text-2xl font-display font-extrabold text-forest-800">{{ compteurs.trouves }}</div>
              <div class="text-xs text-forest-500 mt-0.5">Objets trouvés</div>
            </NuxtLink>
            <NuxtLink to="/resultats" class="card-hover p-5">
              <span class="flex h-10 w-10 items-center justify-center rounded-full bg-forest-50 text-forest-600 mb-3">
                <IconTab name="check" class="h-5 w-5" />
              </span>
              <div class="text-2xl font-display font-extrabold text-forest-800">{{ compteurs.correspondances }}</div>
              <div class="text-xs text-forest-500 mt-0.5">Correspondances</div>
            </NuxtLink>
            <NuxtLink to="/messagerie" class="card-hover p-5">
              <span class="flex h-10 w-10 items-center justify-center rounded-full bg-savane-50 text-savane-600 mb-3">
                <IconTab name="chat" class="h-5 w-5" />
              </span>
              <div class="text-2xl font-display font-extrabold text-forest-800">{{ compteurs.messages }}</div>
              <div class="text-xs text-forest-500 mt-0.5">Messages non lus</div>
            </NuxtLink>
            <div class="card-hover p-5">
              <span class="flex h-10 w-10 items-center justify-center rounded-full bg-forest-50 text-forest-600 mb-3">
                <IconTab name="shield" class="h-5 w-5" />
              </span>
              <div class="text-2xl font-display font-extrabold text-forest-800">{{ compteurs.recuperes }}</div>
              <div class="text-xs text-forest-500 mt-0.5">Objets récupérés</div>
            </div>
          </div>

          <!-- Colonne gauche (listes) + colonne droite (notifications & conseils) -->
          <div class="grid lg:grid-cols-3 gap-5">
            <div class="lg:col-span-2 space-y-5">
              <div class="card overflow-hidden">
                <div class="flex items-center justify-between px-5 py-3.5 border-b border-forest-50">
                  <p class="font-display font-semibold text-sm">Mes objets perdus</p>
                  <NuxtLink to="/mes-recherches" class="text-xs text-savane-600 font-semibold">Voir tout</NuxtLink>
                </div>
                <div v-if="mesPerdus.length" class="divide-y divide-forest-50">
                  <div v-for="d in mesPerdus" :key="d.id" class="flex items-center gap-3 px-5 py-3">
                    <span class="flex h-9 w-9 items-center justify-center rounded-full bg-forest-50 text-forest-600 shrink-0">
                      <IconTab name="card" class="h-4 w-4" />
                    </span>
                    <div class="min-w-0 flex-1">
                      <p class="text-sm font-medium truncate">{{ labelType(d.object_type_id) }}</p>
                      <p class="text-xs text-forest-400">{{ d.ville }} · {{ new Date(d.created_at).toLocaleDateString('fr-FR') }}</p>
                    </div>
                    <span class="badge bg-forest-50 text-forest-500 whitespace-nowrap">{{ infoStatut(d.statut, 'perdu').emoji }} {{ infoStatut(d.statut, 'perdu').label }}</span>
                  </div>
                </div>
                <p v-else class="text-center text-sm text-forest-400 py-8">
                  Aucun objet perdu déclaré.
                  <NuxtLink to="/perdu" class="text-savane-600 font-semibold block mt-1">Déclarer une perte</NuxtLink>
                </p>
              </div>

              <div class="card overflow-hidden">
                <div class="flex items-center justify-between px-5 py-3.5 border-b border-forest-50">
                  <p class="font-display font-semibold text-sm">Objets que j'ai trouvés</p>
                  <NuxtLink to="/mes-objets-trouves" class="text-xs text-savane-600 font-semibold">Voir tout</NuxtLink>
                </div>
                <div v-if="mesTrouves.length" class="divide-y divide-forest-50">
                  <div v-for="d in mesTrouves" :key="d.id" class="flex items-center gap-3 px-5 py-3">
                    <span class="flex h-9 w-9 items-center justify-center rounded-full bg-savane-50 text-savane-600 shrink-0">
                      <IconTab name="search" class="h-4 w-4" />
                    </span>
                    <div class="min-w-0 flex-1">
                      <p class="text-sm font-medium truncate">{{ labelType(d.object_type_id) }}</p>
                      <p class="text-xs text-forest-400">{{ d.ville }} · {{ new Date(d.created_at).toLocaleDateString('fr-FR') }}</p>
                    </div>
                    <span class="badge bg-forest-50 text-forest-500 whitespace-nowrap">{{ infoStatut(d.statut, 'trouve').emoji }} {{ infoStatut(d.statut, 'trouve').label }}</span>
                  </div>
                </div>
                <p v-else class="text-center text-sm text-forest-400 py-8">
                  Aucun objet trouvé déclaré.
                  <NuxtLink to="/trouve" class="text-savane-600 font-semibold block mt-1">Déclarer une trouvaille</NuxtLink>
                </p>
              </div>
            </div>

            <!-- Colonne droite -->
            <div class="space-y-5">
              <div class="card overflow-hidden">
                <div class="flex items-center justify-between px-5 py-3.5 border-b border-forest-50">
                  <p class="font-display font-semibold text-sm">Mes notifications</p>
                  <NuxtLink to="/notifications" class="text-xs text-savane-600 font-semibold">Tout voir</NuxtLink>
                </div>
                <div v-if="mesNotifications.length" class="divide-y divide-forest-50">
                  <div v-for="n in mesNotifications" :key="n.id" class="px-5 py-3">
                    <p class="text-sm font-medium" :class="n.lu ? 'text-forest-600' : 'text-forest-800'">{{ n.titre }}</p>
                    <p class="text-xs text-forest-400 mt-0.5 line-clamp-2">{{ n.corps }}</p>
                  </div>
                </div>
                <p v-else class="text-center text-sm text-forest-400 py-6 px-4">
                  Aucune notification pour l'instant. Vous serez averti dès qu'une correspondance est trouvée.
                </p>
              </div>

              <div class="card p-5 bg-forest-800 text-white">
                <p class="flex items-center gap-1.5 text-[11px] font-bold uppercase tracking-widest text-savane-400 mb-3">
                  <IconTab name="shield" class="h-3 w-3" /> Conseil sécurité
                </p>
                <p class="text-sm text-forest-100/80 leading-relaxed">
                  Ne communiquez jamais votre numéro de téléphone ou votre adresse en dehors de la
                  messagerie RETROUVA. La vérification d'identité protège vos objets contre les
                  fausses réclamations.
                </p>
              </div>

              <NuxtLink to="/carte" class="card-hover p-5 flex items-center gap-3 block">
                <span class="flex h-10 w-10 items-center justify-center rounded-full bg-savane-50 text-savane-600 shrink-0">
                  <IconTab name="pin" class="h-5 w-5" />
                </span>
                <div>
                  <p class="text-sm font-display font-semibold text-forest-800">Voir la carte</p>
                  <p class="text-xs text-forest-400">Objets et points relais autour de vous</p>
                </div>
              </NuxtLink>
            </div>
          </div>
        </template>
      </div>
    </div>
  </div>
</template>
