/**
 * Authentification réelle via Supabase — inscription professionnelle :
 * l'utilisateur crée un compte (infos + mot de passe), reçoit un code pour
 * vérifier son e-mail, puis se connecte ensuite avec e-mail + mot de passe.
 */
export const useAuth = () => {
  const supabase = useSupabase()
  const configured = useSupabaseConfigured()
  const user = useState('retrouva_user', () => null)
  const profile = useState('retrouva_profile', () => null)

  const fetchProfile = async () => {
    if (!configured || !user.value) { profile.value = null; return }
    const { data } = await supabase
      .from('profiles')
      .select('*')
      .eq('id', user.value.id)
      .maybeSingle()
    profile.value = data
  }

  const init = async () => {
    if (!configured) return // .env non renseigné : on n'appelle pas Supabase
    const { data } = await supabase.auth.getSession()
    user.value = data.session?.user || null
    await fetchProfile()

    supabase.auth.onAuthStateChange(async (_event, session) => {
      user.value = session?.user || null
      await fetchProfile()
    })
  }

  const ensureConfigured = () => {
    if (!configured) {
      throw new Error(
        "Supabase n'est pas configuré. Créez un fichier .env (voir .env.example) avec vos clés " +
        'SUPABASE_URL et SUPABASE_ANON_KEY, puis relancez le serveur.'
      )
    }
  }

  // ---------------------------------------------------------------------
  // INSCRIPTION — crée le compte + envoie un code de vérification e-mail.
  // "infos" peut contenir { nom_affiche, telephone, ville, commune } :
  // le déclencheur SQL les copie automatiquement dans la table "profiles".
  // ---------------------------------------------------------------------
  const inscription = async (email, password, infos = {}) => {
    ensureConfigured()
    const { error } = await supabase.auth.signUp({
      email,
      password,
      options: { data: infos }
    })
    if (error) throw error
  }

  // Vérifie le code reçu par e-mail après l'inscription
  const verifierInscription = async (email, token) => {
    ensureConfigured()
    const { data, error } = await supabase.auth.verifyOtp({ email, token, type: 'signup' })
    if (error) throw error
    user.value = data.user
    await fetchProfile()
  }

  // Renvoie un nouveau code de vérification (si le premier a expiré)
  const renvoyerCodeInscription = async (email) => {
    ensureConfigured()
    const { error } = await supabase.auth.resend({ type: 'signup', email })
    if (error) throw error
  }

  // ---------------------------------------------------------------------
  // CONNEXION — e-mail + mot de passe (le mode normal, une fois vérifié)
  // ---------------------------------------------------------------------
  const connexion = async (email, password) => {
    ensureConfigured()
    const { data, error } = await supabase.auth.signInWithPassword({ email, password })
    if (error) throw error
    user.value = data.user
    await fetchProfile()
  }

  // ---------------------------------------------------------------------
  // MOT DE PASSE OUBLIÉ
  // ---------------------------------------------------------------------
  const demanderReinitialisation = async (email) => {
    ensureConfigured()
    const redirectTo = typeof window !== 'undefined' ? `${window.location.origin}/reinitialiser-mot-de-passe` : undefined
    const { error } = await supabase.auth.resetPasswordForEmail(email, { redirectTo })
    if (error) throw error
  }

  // Chemin par code (recommandé) : évite le souci des liens "pré-visités" par
  // certains clients mail (Gmail notamment), qui consomment le lien avant
  // même que l'utilisateur ne clique dessus.
  const verifierReinitialisation = async (email, token, nouveauMotDePasse) => {
    ensureConfigured()
    const { error: erreurVerif } = await supabase.auth.verifyOtp({ email, token, type: 'recovery' })
    if (erreurVerif) throw erreurVerif
    const { error: erreurMaj } = await supabase.auth.updateUser({ password: nouveauMotDePasse })
    if (erreurMaj) throw erreurMaj
  }

  const definirNouveauMotDePasse = async (nouveauMotDePasse) => {
    ensureConfigured()
    const { error } = await supabase.auth.updateUser({ password: nouveauMotDePasse })
    if (error) throw error
  }

  // ---------------------------------------------------------------------
  // CONNEXION SANS MOT DE PASSE — envoie un code par e-mail (template
  // Supabase "Magic Link or OTP"), sans lien à cliquer côté utilisateur.
  // ---------------------------------------------------------------------
  const demanderCodeConnexion = async (email) => {
    ensureConfigured()
    const { error } = await supabase.auth.signInWithOtp({ email })
    if (error) throw error
  }

  const verifierCodeConnexion = async (email, token) => {
    ensureConfigured()
    const { data, error } = await supabase.auth.verifyOtp({ email, token, type: 'email' })
    if (error) throw error
    user.value = data.user
    await fetchProfile()
  }

  // ---------------------------------------------------------------------
  // CHANGEMENT D'ADRESSE E-MAIL — envoie un code à la nouvelle adresse
  // (template Supabase "Change Email Address") pour la confirmer.
  // ---------------------------------------------------------------------
  const demanderChangementEmail = async (nouvelEmail) => {
    ensureConfigured()
    if (!user.value) throw new Error('Non connecté.')
    const { error } = await supabase.auth.updateUser({ email: nouvelEmail })
    if (error) throw error
  }

  const confirmerChangementEmail = async (nouvelEmail, token) => {
    ensureConfigured()
    const { data, error } = await supabase.auth.verifyOtp({ email: nouvelEmail, token, type: 'email_change' })
    if (error) throw error
    user.value = data.user
    await fetchProfile()
  }

  // ---------------------------------------------------------------------
  // VÉRIFICATION DU TÉLÉPHONE PAR SMS — nécessite qu'un fournisseur SMS
  // (Twilio, Vonage, MessageBird...) soit configuré dans Dashboard
  // Supabase → Authentication → Providers → Phone (comme le SMTP pour les
  // e-mails). Une fois le code confirmé, le numéro et son statut vérifié
  // sont enregistrés sur le profil public.
  // ---------------------------------------------------------------------
  const demanderVerificationTelephone = async (numero) => {
    ensureConfigured()
    if (!user.value) throw new Error('Non connecté.')
    const { error } = await supabase.auth.updateUser({ phone: numero })
    if (error) throw error
  }

  const confirmerVerificationTelephone = async (numero, token) => {
    ensureConfigured()
    if (!user.value) throw new Error('Non connecté.')
    const { error: erreurVerif } = await supabase.auth.verifyOtp({ phone: numero, token, type: 'phone_change' })
    if (erreurVerif) throw erreurVerif
    const { error: erreurProfil } = await supabase
      .from('profiles')
      .update({ telephone: numero, telephone_verifie: true })
      .eq('id', user.value.id)
    if (erreurProfil) throw erreurProfil
    await fetchProfile()
  }

  // ---------------------------------------------------------------------
  // SUPPRESSION DE COMPTE — par sécurité, redemande le mot de passe avant
  // d'appeler la route serveur /api/compte/supprimer (qui utilise la clé
  // service_role, jamais exposée au navigateur). Le profil et toutes les
  // données liées sont supprimés en cascade côté base.
  // ---------------------------------------------------------------------
  const supprimerCompte = async (motDePasseActuel) => {
    ensureConfigured()
    if (!user.value) throw new Error('Non connecté.')

    // Confirme l'identité avant une action irréversible.
    const { error: erreurConfirmation } = await supabase.auth.signInWithPassword({
      email: user.value.email,
      password: motDePasseActuel
    })
    if (erreurConfirmation) throw new Error('Mot de passe incorrect.')

    const { data: sessionData } = await supabase.auth.getSession()
    const jeton = sessionData.session?.access_token
    if (!jeton) throw new Error('Session invalide, reconnectez-vous.')

    const config = useRuntimeConfig()
    const reponse = await $fetch(`${config.public.apiBaseUrl}/api/compte/supprimer`, {
      method: 'POST',
      headers: { Authorization: `Bearer ${jeton}` }
    }).catch((e) => {
      throw new Error(e.data?.statusMessage || e.message || 'Erreur lors de la suppression.')
    })

    if (!reponse?.succes) throw new Error('La suppression a échoué.')

    await supabase.auth.signOut()
    user.value = null
    profile.value = null
  }

  const signOut = async () => {
    if (!configured) return
    await supabase.auth.signOut()
    user.value = null
    profile.value = null
  }

  // Déconnecte TOUTES les sessions actives de ce compte (autres téléphones/
  // navigateurs connectés), utile si un appareil est perdu ou volé.
  const signOutPartout = async () => {
    ensureConfigured()
    const { error } = await supabase.auth.signOut({ scope: 'global' })
    if (error) throw error
    user.value = null
    profile.value = null
  }

  // ---------------------------------------------------------------------
  // MISE À JOUR DU PROFIL — champs éditables uniquement (jamais le rôle,
  // qui est protégé côté base par un déclencheur en plus de cette liste
  // blanche côté client : voir migration_19).
  // ---------------------------------------------------------------------
  const mettreAJourProfil = async (infos = {}) => {
    ensureConfigured()
    if (!user.value) throw new Error('Non connecté.')
    const champsAutorises = ['nom_affiche', 'telephone', 'ville', 'commune', 'avatar_url']
    const payload = {}
    for (const champ of champsAutorises) {
      if (champ in infos) payload[champ] = infos[champ]
    }
    const { error } = await supabase.from('profiles').update(payload).eq('id', user.value.id)
    if (error) throw error
    await fetchProfile()
  }

  // Envoie une photo dans le bucket "avatars" (dossier = id utilisateur,
  // comme pour "objets-trouves") puis enregistre l'URL publique sur le profil.
  const televerserAvatar = async (fichier) => {
    ensureConfigured()
    if (!user.value) throw new Error('Non connecté.')
    const chemin = `${user.value.id}/${Date.now()}-${fichier.name}`
    const { televerserAvecRetry } = useUploadImage()
    const { error: erreurUpload } = await televerserAvecRetry(supabase, 'avatars', chemin, fichier)
    if (erreurUpload) throw erreurUpload
    const { data } = supabase.storage.from('avatars').getPublicUrl(chemin)
    await mettreAJourProfil({ avatar_url: data.publicUrl })
  }

  return {
    user, profile, configured, init, fetchProfile,
    inscription, verifierInscription, renvoyerCodeInscription,
    connexion, demanderReinitialisation, verifierReinitialisation, definirNouveauMotDePasse,
    demanderCodeConnexion, verifierCodeConnexion,
    demanderChangementEmail, confirmerChangementEmail,
    demanderVerificationTelephone, confirmerVerificationTelephone,
    supprimerCompte,
    mettreAJourProfil, televerserAvatar,
    signOut, signOutPartout
  }
}
