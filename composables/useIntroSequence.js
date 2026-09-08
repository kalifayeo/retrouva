// Permet à <IntroVideo> de savoir quand les diapositives de
// <OnboardingIntro> sont terminées, pour l'option "vidéo après
// l'introduction" choisie dans /admin/introduction. Utilise useState
// (état partagé Nuxt) plutôt qu'un simple ref de module, pour rester
// cohérent avec le reste du projet (voir useAuth.js, useTheme.js).
export const useIntroSequence = () => {
  const slidesTerminees = useState('retrouva_intro_slides_terminees', () => false)
  return { slidesTerminees }
}
