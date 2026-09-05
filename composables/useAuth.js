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

  const signOut = async () => {
    if (!configured) return
    await supabase.auth.signOut()
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
    mettreAJourProfil, televerserAvatar,
    signOut
  }
}
