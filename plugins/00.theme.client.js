export default defineNuxtPlugin(() => {
  const { initialiser } = useTheme()
  initialiser()
})
