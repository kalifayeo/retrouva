// POST /api/dons/creer
// Remplace l'ancienne insertion directe depuis le navigateur
// (supabase.from('donations').insert(...) dans pages/don.vue), qui
// reposait sur une policy RLS ouverte à tous ("with check (true)") sans
// aucune limite de fréquence. Ici :
//  1) on valide montant/téléphone côté serveur (jamais confiance au client) ;
//  2) on applique une limite de fréquence par IP (server/utils/donRateLimit.js) ;
//  3) on insère avec la clé service_role, en enregistrant l'IP d'origine
//     pour pouvoir appliquer cette même limite à la prochaine tentative.
export default defineEventHandler(async (event) => {
  const body = await readBody(event)

  const montant = Number(body?.montant)
  if (!Number.isFinite(montant) || montant <= 0 || montant > 5_000_000) {
    throw createError({ statusCode: 400, statusMessage: 'Montant invalide.' })
  }

  const reference = String(body?.reference || '').trim()
  if (!/^DON-[A-Z0-9-]{6,40}$/.test(reference)) {
    throw createError({ statusCode: 400, statusMessage: 'Référence invalide.' })
  }

  // Coordonnées facultatives : bornées en longueur pour éviter tout abus
  // (ex. un script envoyant des méga-chaînes pour saturer la base).
  const nom = String(body?.nom || '').trim().slice(0, 120) || null
  const telephone = String(body?.telephone || '').trim().slice(0, 30) || null
  const message = String(body?.message || '').trim().slice(0, 500) || null
  const email = String(body?.email || '').trim().toLowerCase().slice(0, 200)
  const emailDonateur = email && email.includes('@') ? email : null
  const typeDonateur = body?.typeDonateur === 'entreprise' ? 'entreprise' : 'particulier'
  const raisonSociale = typeDonateur === 'entreprise'
    ? String(body?.raisonSociale || '').trim().slice(0, 150) || null
    : null
  const paymentMethodId = typeof body?.paymentMethodId === 'string' && !body.paymentMethodId.startsWith('defaut-')
    ? body.paymentMethodId
    : null

  const admin = supabaseAdmin()
  const ip = ipDepuisRequete(event)

  await verifierLimiteDons(admin, ip)

  // Donateur connecté (facultatif) : si un jeton valide est fourni, on
  // relie le don à son compte pour qu'il retrouve l'historique de ses
  // dons sur /mes-dons (voir migration_28). Un jeton absent ou invalide
  // n'empêche jamais le don — il reste alors anonyme, comme avant.
  let donorUserId = null
  const authHeader = getHeader(event, 'authorization') || ''
  const jeton = authHeader.replace(/^Bearer\s+/i, '')
  if (jeton) {
    const { data: donneesUtilisateur } = await admin.auth.getUser(jeton)
    donorUserId = donneesUtilisateur?.user?.id || null
  }

  const { data, error } = await admin
    .from('donations')
    .insert({
      reference,
      nom_donateur: nom,
      telephone_donateur: telephone,
      email_donateur: emailDonateur,
      type_donateur: typeDonateur,
      raison_sociale: raisonSociale,
      montant,
      payment_method_id: paymentMethodId,
      message,
      ip_creation: ip,
      donor_user_id: donorUserId
    })
    .select('id, reference')
    .single()

  if (error) {
    // Référence dupliquée (contrainte unique) ou autre souci d'insertion :
    // on ne bloque jamais l'affichage des instructions de paiement côté
    // front (voir pages/don.vue), donc une erreur ici reste non bloquante
    // pour l'utilisateur, mais on la remonte pour être journalisée.
    throw createError({ statusCode: 502, statusMessage: "Impossible d'enregistrer le don pour le moment." })
  }

  return { id: data.id, reference: data.reference }
})
