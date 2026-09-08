<script setup>
definePageMeta({ middleware: 'admin', layout: 'admin' })

const supabase = useSupabase()
const { profile } = useAuth()

const kpis = ref([
  { label: 'Déclarations perdues', value: '—', icon: 'search' },
  { label: 'Déclarations trouvées', value: '—', icon: 'pin' },
  { label: 'Correspondances', value: '—', icon: 'handshake' },
  { label: 'Signalements en attente', value: '—', icon: 'bell' },
  { label: 'Partenaires actifs', value: '—', icon: 'handshake' }
])

// Filtré selon le rôle : un modérateur ne voit ici que les sections vers
// lesquelles il a réellement le droit de naviguer.
const sectionsCompletes = [
  { label: 'Utilisateurs', to: '/admin/utilisateurs', icon: 'user', desc: 'Gérer les comptes et les rôles' },
  { label: 'Déclarations', to: '/admin/declarations', icon: 'search', desc: 'Objets perdus et trouvés' },
  { label: 'Correspondances', to: '/admin/correspondances', icon: 'handshake', desc: 'Voir, masquer ou supprimer' },
  { label: 'Signalements', to: '/admin/signalements', icon: 'bell', desc: 'Modération et fraude' },
  { label: 'Partenaires', to: '/admin/partenaires', icon: 'handshake', desc: 'Points relais et organismes partenaires' },
  { label: 'Dons', to: '/admin/dons', icon: 'gift', desc: 'Moyens de paiement et suivi des dons' },
  { label: 'Support technique', to: '/admin/support', icon: 'chat', desc: 'Conversations du chat flottant' },
  { label: 'Contenu du site', to: '/admin/contenu', icon: 'card', desc: 'Textes, fond visuel et numéro WhatsApp' },
  { label: 'Bannières & pub', to: '/admin/bannieres', icon: 'megaphone', desc: 'Publicités internes et entreprises partenaires' },
  { label: 'Pop-up', to: '/admin/popups', icon: 'bell', desc: "Messages d'accueil ou promotionnels" },
  { label: 'Événements', to: '/admin/evenements', icon: 'clock', desc: 'Séances et journées de restitution' },
  { label: 'Introduction du site', to: '/admin/introduction', icon: 'video', desc: 'Vidéo de présentation et diapositives de bienvenue' }
]

const sections = computed(() => sectionsCompletes.filter((s) => peutAccederPage(profile.value?.role, s.to)))

const charger = async () => {
  if (!supabase) return
  const [lost, found, matches, reports, partenaires] = await Promise.all([
    supabase.from('lost_reports').select('id', { count: 'exact', head: true }),
    supabase.from('found_reports').select('id', { count: 'exact', head: true }),
    supabase.from('matches').select('id', { count: 'exact', head: true }),
    supabase.from('reports').select('id', { count: 'exact', head: true }).eq('statut', 'ouvert'),
    supabase.from('partners').select('id', { count: 'exact', head: true }).eq('actif', true)
  ])
  kpis.value[0].value = lost.count ?? 0
  kpis.value[1].value = found.count ?? 0
  kpis.value[2].value = matches.count ?? 0
  kpis.value[3].value = reports.count ?? 0
  kpis.value[4].value = partenaires.count ?? 0
}

onMounted(charger)
</script>

<template>
  <div class="section py-8 md:py-12">
    <div class="container-app">
      <div class="flex items-center justify-between mb-1">
        <h1 class="text-2xl font-bold">Administration</h1>
        <span class="badge-green">{{ profile?.role }}</span>
      </div>
      <p class="text-forest-700/70 mb-8">Vue d'ensemble de la plateforme RETROUVA, données en direct.</p>

      <div class="grid grid-cols-2 lg:grid-cols-5 gap-4 mb-10">
        <div v-for="k in kpis" :key="k.label" class="card p-5">
          <span class="flex h-9 w-9 items-center justify-center rounded-full bg-forest-50 text-forest-700 mb-3">
            <IconTab :name="k.icon" class="h-4 w-4" />
          </span>
          <div class="text-2xl font-display font-extrabold text-forest-800">{{ k.value }}</div>
          <div class="text-xs text-forest-500">{{ k.label }}</div>
        </div>
      </div>

      <div class="grid sm:grid-cols-2 lg:grid-cols-3 gap-4">
        <NuxtLink v-for="s in sections" :key="s.to" :to="s.to" class="card-hover p-5 flex items-start gap-3">
          <span class="flex h-10 w-10 shrink-0 items-center justify-center rounded-full bg-forest-800 text-white">
            <IconTab :name="s.icon" class="h-5 w-5" />
          </span>
          <div>
            <p class="font-display font-semibold text-sm">{{ s.label }}</p>
            <p class="text-xs text-forest-500 mt-0.5">{{ s.desc }}</p>
          </div>
        </NuxtLink>
      </div>
    </div>
  </div>
</template>
