<script setup>
const props = defineProps({
  interactive: { type: Boolean, default: true },
  hauteur: { type: String, default: '420px' }
})

const supabase = useSupabase()
const villesCoordonnees = useVillesCoordonnees()
const conteneur = ref(null)
let carte = null

const chargerEtDessiner = async () => {
  if (!supabase || typeof window === 'undefined') return

  const L = (await import('leaflet')).default

  carte = L.map(conteneur.value, {
    zoomControl: props.interactive,
    dragging: props.interactive,
    scrollWheelZoom: props.interactive,
    doubleClickZoom: props.interactive,
    touchZoom: props.interactive,
    boxZoom: props.interactive,
    keyboard: props.interactive,
    attributionControl: props.interactive
  }).setView([7.5399, -5.5471], props.interactive ? 7 : 6.4)

  L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
    attribution: props.interactive ? '&copy; OpenStreetMap' : '',
    maxZoom: 18
  }).addTo(carte)

  const pointIcon = (couleur) => L.divIcon({
    className: '',
    html: `<div style="background:${couleur};width:14px;height:14px;border-radius:9999px;border:2px solid white;box-shadow:0 1px 4px rgba(0,0,0,.4)"></div>`,
    iconSize: [14, 14],
    iconAnchor: [7, 7]
  })

  const { data, error } = await supabase.rpc('public_carte_data')
  if (!error && data) {
    for (const row of data) {
      const base = villesCoordonnees[row.ville]
      if (!base) continue

      if (row.perdus > 0) {
        L.marker([base[0] + 0.03, base[1] - 0.03], { icon: pointIcon('#DC2626') })
          .addTo(carte)
          .bindPopup(`<strong>${row.ville}</strong><br/>${row.perdus} objet${row.perdus > 1 ? 's' : ''} perdu${row.perdus > 1 ? 's' : ''}`)
      }
      if (row.trouves > 0) {
        L.marker([base[0] - 0.03, base[1] + 0.03], { icon: pointIcon('#1F5E37') })
          .addTo(carte)
          .bindPopup(`<strong>${row.ville}</strong><br/>${row.trouves} objet${row.trouves > 1 ? 's' : ''} trouvé${row.trouves > 1 ? 's' : ''}`)
      }
    }
  }

  // Points partenaires (🔵) — positions précises car ce sont des adresses
  // professionnelles publiques, pas des localisations personnelles.
  const { data: relais } = await supabase
    .from('pickup_points')
    .select('nom, ville, commune, adresse, latitude, longitude')
    .eq('actif', true)

  for (const r of relais || []) {
    if (!r.latitude || !r.longitude) continue
    L.marker([r.latitude, r.longitude], { icon: pointIcon('#2563EB') })
      .addTo(carte)
      .bindPopup(`<strong>${r.nom}</strong><br/>${r.adresse || r.commune || r.ville}`)
  }
}

onMounted(() => {
  chargerEtDessiner()
})

onBeforeUnmount(() => {
  if (carte) carte.remove()
})
</script>

<template>
  <div>
    <div ref="conteneur" :style="{ height: hauteur }" class="w-full rounded-2xl overflow-hidden z-0"></div>
  </div>
</template>

<style>
@import 'leaflet/dist/leaflet.css';
</style>
