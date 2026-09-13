// Notifications push réelles sur l'app mobile (Capacitor). Jusqu'ici,
// @capacitor/push-notifications figurait dans package.json sans jamais
// être utilisé : aucun jeton d'appareil n'était demandé ni enregistré, et
// le serveur n'avait donc aucun moyen d'envoyer quoi que ce soit. Ce
// composable :
//  1) demande la permission et enregistre l'appareil auprès d'APNs/FCM ;
//  2) sauvegarde le jeton obtenu dans la table "push_tokens" (migration_28),
//     pour que le serveur puisse ensuite l'utiliser (server/utils/
//     envoyerPush.js, ex. lors de la confirmation d'un don) ;
//  3) redirige vers la bonne page quand l'utilisateur appuie sur une
//     notification reçue (même champ "lien" que les notifications in-app,
//     voir migration_16).
//
// N'a aucun effet sur le web (Capacitor.isNativePlatform() === false) :
// le site continue de fonctionner uniquement avec les notifications
// in-app existantes (cloche du header), sans régression.
export const usePushNotifications = () => {
  const { user } = useAuth()
  const supabase = useSupabase()
  const configured = useSupabaseConfigured()
  const initialise = useState('retrouva_push_initialise', () => false)

  const enregistrerJeton = async (jeton, plateforme) => {
    if (!configured || !user.value) return
    await supabase.from('push_tokens').upsert(
      { user_id: user.value.id, jeton, plateforme, derniere_utilisation: new Date().toISOString() },
      { onConflict: 'user_id,jeton' }
    )
  }

  const initialiser = async () => {
    if (initialise.value) return // déjà fait pour cette session app
    if (typeof window === 'undefined') return

    let Capacitor, PushNotifications
    try {
      ;({ Capacitor } = await import('@capacitor/core'))
      ;({ PushNotifications } = await import('@capacitor/push-notifications'))
    } catch (e) {
      return // paquets absents (ex. build web pur) : rien à faire
    }

    if (!Capacitor.isNativePlatform()) return
    if (!configured || !user.value) return

    initialise.value = true
    const plateforme = Capacitor.getPlatform() // 'android' | 'ios'

    try {
      const permission = await PushNotifications.checkPermissions()
      let statut = permission.receive
      if (statut === 'prompt' || statut === 'prompt-with-rationale') {
        statut = (await PushNotifications.requestPermissions()).receive
      }
      if (statut !== 'granted') return

      await PushNotifications.register()

      PushNotifications.addListener('registration', (jeton) => {
        enregistrerJeton(jeton.value, plateforme)
      })

      PushNotifications.addListener('registrationError', () => {
        // Best-effort : l'utilisateur garde les notifications in-app même
        // si l'enregistrement push échoue (ex. Google Play Services absent).
      })

      // L'utilisateur appuie sur une notification reçue (app en arrière-plan
      // ou fermée) : on le redirige vers la page concernée, comme pour un
      // clic sur une notification in-app.
      PushNotifications.addListener('pushNotificationActionPerformed', (action) => {
        const lien = action.notification?.data?.lien
        if (lien) navigateTo(lien)
      })
    } catch (e) {
      // Rien de plus à faire : dégradation silencieuse vers les
      // notifications in-app uniquement.
    }
  }

  // Remarque sur la déconnexion : on ne tente pas de retrouver puis
  // supprimer le jeton de l'appareil ici (la seule façon fiable serait de
  // le garder en mémoire depuis l'enregistrement). En pratique ce n'est
  // pas nécessaire : un jeton devenu invalide (désinstallation, appareil
  // ré-attribué à un autre compte...) est de toute façon nettoyé
  // automatiquement côté serveur dès le premier envoi en échec — voir
  // "jetonsInvalides" dans server/utils/envoyerPush.js.
  const reinitialiser = () => { initialise.value = false }

  return { initialiserPushNotifications: initialiser, reinitialiserPushNotifications: reinitialiser }
}
