export const tempsRelatif = (date) => {
  const diffMs = Date.now() - new Date(date).getTime()
  const min = Math.round(diffMs / 60000)
  if (min < 1) return "à l'instant"
  if (min < 60) return `il y a ${min} min`
  const h = Math.round(min / 60)
  if (h < 24) return `il y a ${h} h`
  const j = Math.round(h / 24)
  if (j < 7) return `il y a ${j} j`
  const sem = Math.round(j / 7)
  return `il y a ${sem} sem`
}
