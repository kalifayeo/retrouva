// Directive v-reveal : fait apparaître un élément (fondu + léger déplacement
// vers le haut) lorsqu'il entre dans la zone visible au scroll. Utilisée sur
// les sections de l'accueil pour une navigation plus vivante, sans rien
// casser du style existant — c'est une simple couche d'animation posée sur
// les mêmes blocs.
//
// Usage :
//   <section v-reveal>...</section>
//   <div v-reveal="{ delay: 80, type: 'up' }">...</div>
//
// Respecte "prefers-reduced-motion" via les règles CSS dans assets/css/main.css
// (voir [data-reveal] et la media query associée).

export default defineNuxtPlugin((nuxtApp) => {
  let observer = null

  const getObserver = () => {
    if (observer) return observer
    observer = new IntersectionObserver(
      (entries) => {
        for (const entry of entries) {
          if (entry.isIntersecting) {
            entry.target.classList.add('is-visible')
            observer.unobserve(entry.target)
          }
        }
      },
      { threshold: 0.12, rootMargin: '0px 0px -8% 0px' }
    )
    return observer
  }

  nuxtApp.vueApp.directive('reveal', {
    mounted(el, binding) {
      const options = binding.value || {}
      el.setAttribute('data-reveal', options.type || 'up')
      if (options.delay) el.style.transitionDelay = `${options.delay}ms`

      // Si l'élément est déjà visible à l'affichage initial (ex. juste sous
      // le pli sur un grand écran), on évite un délai artificiel : il
      // apparaît immédiatement plutôt que de laisser un blanc au chargement.
      const rect = el.getBoundingClientRect()
      const dejaVisible = rect.top < window.innerHeight * 0.92 && rect.bottom > 0
      if (dejaVisible) {
        requestAnimationFrame(() => el.classList.add('is-visible'))
        return
      }

      getObserver().observe(el)
    },
    unmounted(el) {
      if (observer) observer.unobserve(el)
    }
  })
})
