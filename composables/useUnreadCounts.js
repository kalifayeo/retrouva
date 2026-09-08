// Compteurs partagés entre AppHeader (badge cloche + menu compte) et la
// barre de navigation mobile (badge sur l'onglet Messages), pour éviter deux
// requêtes indépendantes et garder les deux affichages synchronisés.
export const useUnreadCounts = () => {
  const { user } = useAuth()
  const supabase = useSupabase()

  const notificationsNonLues = useState('retrouva_notifications_non_lues', () => 0)
  const messagesNonLus = useState('retrouva_messages_non_lus', () => 0)

  const charger = async () => {
    if (!supabase || !user.value) {
      notificationsNonLues.value = 0
      messagesNonLus.value = 0
      return
    }

    const { count } = await supabase
      .from('notifications')
      .select('id', { count: 'exact', head: true })
      .eq('user_id', user.value.id)
      .eq('lu', false)
    notificationsNonLues.value = count ?? 0

    const { count: countMessages } = await supabase
      .from('messages')
      .select('id', { count: 'exact', head: true })
      .eq('destinataire_id', user.value.id)
      .eq('lu', false)
    messagesNonLus.value = countMessages ?? 0
  }

  return { notificationsNonLues, messagesNonLus, charger }
}
