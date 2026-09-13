// Génère à la volée un PDF d'attestation de don (reçu fiscal), sans
// jamais le stocker en clair sur le serveur — chaque téléchargement
// régénère le document, seul le numéro d'attestation (voir fonction SQL
// "generer_numero_attestation", migration_28) reste stable pour un même
// don, afin qu'un donateur qui télécharge plusieurs fois obtienne toujours
// le même numéro de référence.
//
// Pensé en priorité pour les dons d'entreprises partenaires (qui ont
// besoin d'un justificatif pour leur comptabilité), mais disponible pour
// tout don confirmé, particulier compris.
//
// RETROUVA n'étant pas nécessairement une association reconnue d'utilité
// publique ouvrant droit à une réduction d'impôt, ce document est un
// simple "reçu de don" / justificatif de versement — PAS une attestation
// fiscale au sens de la loi ivoirienne, qui suppose un agrément officiel.
// Adaptez le texte ci-dessous si RETROUVA obtient un tel agrément.
import { PDFDocument, StandardFonts, rgb } from 'pdf-lib'

export const genererAttestationPdf = async (admin, donId) => {
  const { data: don, error } = await admin
    .from('donations')
    .select('*, payment_methods(nom)')
    .eq('id', donId)
    .maybeSingle()

  if (error || !don) throw new Error('Don introuvable.')
  if (don.statut !== 'confirme') throw new Error("Ce don n'est pas encore confirmé.")

  // Numéro stable — voir la fonction SQL dédiée (évite toute course entre
  // deux générations simultanées, et garantit qu'il n'est calculé qu'une
  // seule fois par don).
  const { data: numero, error: erreurNumero } = await admin.rpc('generer_numero_attestation', { p_don_id: donId })
  if (erreurNumero) throw new Error("Impossible d'attribuer un numéro d'attestation.")

  const nomBeneficiaire = don.type_donateur === 'entreprise' && don.raison_sociale
    ? don.raison_sociale
    : (don.nom_donateur || 'Donateur anonyme')

  const dateConfirmation = don.confirmed_at ? new Date(don.confirmed_at) : new Date(don.created_at)
  const dateAffichee = dateConfirmation.toLocaleDateString('fr-FR', { year: 'numeric', month: 'long', day: 'numeric' })
  const montantAffiche = `${Number(don.montant).toLocaleString('fr-FR')} FCFA`

  const pdf = await PDFDocument.create()
  const page = pdf.addPage([595, 842]) // A4 portrait, en points
  const police = await pdf.embedFont(StandardFonts.Helvetica)
  const policeGrasse = await pdf.embedFont(StandardFonts.HelveticaBold)

  const vertForet = rgb(0.043, 0.239, 0.141) // #0B3D24, couleur de marque RETROUVA
  const gris = rgb(0.35, 0.35, 0.35)

  let y = 780
  const ecrire = (texte, { taille = 11, police: p = police, couleur = rgb(0, 0, 0), gras = false } = {}) => {
    page.drawText(texte, { x: 56, y, size: taille, font: gras ? policeGrasse : p, color: couleur })
    y -= taille + 10
  }

  ecrire('RETROUVA', { taille: 22, gras: true, couleur: vertForet })
  ecrire('Trouver. Connecter. Restituer.', { taille: 10, couleur: gris })
  y -= 14

  ecrire('REÇU DE DON', { taille: 16, gras: true })
  ecrire(`N° ${numero}`, { taille: 11, couleur: gris })
  y -= 10

  ecrire(`Nous certifions avoir reçu de :`, { taille: 11 })
  ecrire(nomBeneficiaire, { taille: 13, gras: true })
  y -= 4

  ecrire(`la somme de : ${montantAffiche}`, { taille: 12, gras: true })
  ecrire(`Référence du don : ${don.reference}`, { taille: 11 })
  if (don.payment_methods?.nom) ecrire(`Moyen de paiement : ${don.payment_methods.nom}`, { taille: 11 })
  ecrire(`Date de confirmation : ${dateAffichee}`, { taille: 11 })
  y -= 14

  ecrire('Ce don a été affecté au fonctionnement de la plateforme RETROUVA, service gratuit', { taille: 10, couleur: gris })
  ecrire('d\'aide à la restitution d\'objets et documents perdus en Côte d\'Ivoire.', { taille: 10, couleur: gris })
  y -= 10
  ecrire('Ce document est un reçu de versement et ne constitue pas, en l\'état, une attestation', { taille: 9, couleur: gris })
  ecrire('ouvrant droit à une réduction ou un crédit d\'impôt au sens du Code Général des Impôts.', { taille: 9, couleur: gris })
  y -= 30

  ecrire(`Fait à Abidjan, le ${new Date().toLocaleDateString('fr-FR')}`, { taille: 10 })
  ecrire('Pour RETROUVA,', { taille: 10 })
  ecrire("L'équipe RETROUVA", { taille: 11, gras: true })

  return pdf.save()
}
