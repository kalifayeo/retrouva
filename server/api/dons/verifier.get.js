// GET /api/dons/verifier?ref=<reference>
// Utilisée par pages/don.vue au retour de Wave/Orange Money : au lieu de
// se fier à "?paiement=succes" dans l'URL (que n'importe qui peut taper
// à la main), on redemande ici le VRAI statut, stocké en base par les
// webhooks vérifiés (server/api/dons/orange-notification.post.js et
// server/api/dons/wave-webhook.post.js).
//
// Ne renvoie que le strict nécessaire à l'affichage (statut, montant) —
// jamais les coordonnées du donateur (nom, téléphone), qui restent
// réservées à l'administration via les policies RLS existantes.
export default defineEventHandler(async (event) => {
  const reference = String(getQuery(event).ref || '').trim()
  if (!/^DON-[A-Z0-9-]{6,40}$/.test(reference)) {
    throw createError({ statusCode: 400, statusMessage: 'Référence invalide.' })
  }

  const admin = supabaseAdmin()
  const { data, error } = await admin
    .from('donations')
    .select('statut, montant, verified_at')
    .eq('reference', reference)
    .maybeSingle()

  if (error || !data) {
    throw createError({ statusCode: 404, statusMessage: 'Don introuvable.' })
  }

  return {
    statut: data.statut, // 'en_attente' | 'confirme' | 'annule'
    montant: data.montant,
    verifie: !!data.verified_at
  }
})
