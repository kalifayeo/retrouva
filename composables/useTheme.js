// Mode sombre / clair — préférence mémorisée dans le navigateur, appliquée
// via la classe "dark" sur <html> (stratégie Tailwind darkMode: 'class').
export const useTheme = () => {
  const theme = useState('retrouva_theme', () => 'light')

  const appliquer = (valeur) => {
    if (typeof document === 'undefined') return
    document.documentElement.classList.toggle('dark', valeur === 'dark')
  }

  const initialiser = () => {
    if (typeof window === 'undefined') return
    const enregistre = localStorage.getItem('retrouva_theme')
    const valeur = enregistre || (window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light')
    theme.value = valeur
    appliquer(valeur)
  }

  const basculer = () => {
    theme.value = theme.value === 'dark' ? 'light' : 'dark'
    localStorage.setItem('retrouva_theme', theme.value)
    appliquer(theme.value)
  }

  return { theme, initialiser, basculer }
}
