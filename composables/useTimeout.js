/**
 * Empêche un écran de rester bloqué sur "Chargement…" indéfiniment si une
 * requête Supabase ne répond jamais (blocage réseau silencieux). Passé le
 * délai, la promesse est rejetée avec un message clair plutôt que de rester
 * en attente pour toujours.
 */
export const avecDelai = (promesse, ms = 12000) => {
  return Promise.race([
    promesse,
    new Promise((_, reject) =>
      setTimeout(() => reject(new Error('Délai dépassé : le serveur met trop de temps à répondre. Vérifiez votre connexion et réessayez.')), ms)
    )
  ])
}
