// Deux problèmes fréquents avec l'envoi d'images vers Supabase Storage :
// 1) une photo de plusieurs Mo prise avec un téléphone récent peut dépasser
//    le temps que tolère la passerelle → erreur HTTP 502 côté navigateur,
//    alors que le bucket est correctement configuré ;
// 2) une erreur réellement temporaire (502/503) ne se reproduit pas
//    forcément si on réessaie tout de suite.
// Ce composable réduit une image trop grande avant l'envoi (via un
// <canvas>, sans dépendance supplémentaire) et retente une fois en cas
// d'erreur passagère.
export const useUploadImage = () => {
  const compresserImage = (fichier, { maxLargeur = 1600, maxHauteur = 1600, qualite = 0.82 } = {}) => {
    return new Promise((resolve) => {
      if (typeof window === 'undefined' || !fichier.type?.startsWith('image/') || fichier.type === 'image/gif') {
        // On laisse les GIF (animation) et les fichiers non-image tels quels.
        resolve(fichier)
        return
      }
      const lecteur = new FileReader()
      lecteur.onload = () => {
        const img = new Image()
        img.onload = () => {
          let { width, height } = img
          if (width > maxLargeur || height > maxHauteur) {
            const ratio = Math.min(maxLargeur / width, maxHauteur / height)
            width = Math.round(width * ratio)
            height = Math.round(height * ratio)
          }
          const canvas = document.createElement('canvas')
          canvas.width = width
          canvas.height = height
          const ctx = canvas.getContext('2d')
          if (!ctx) { resolve(fichier); return }
          ctx.drawImage(img, 0, 0, width, height)
          canvas.toBlob((blob) => {
            if (!blob || blob.size >= fichier.size) { resolve(fichier); return } // pas la peine de garder une version plus lourde
            const nom = fichier.name.replace(/\.\w+$/, '') + '.jpg'
            resolve(new File([blob], nom, { type: 'image/jpeg' }))
          }, 'image/jpeg', qualite)
        }
        img.onerror = () => resolve(fichier)
        img.src = lecteur.result
      }
      lecteur.onerror = () => resolve(fichier)
      lecteur.readAsDataURL(fichier)
    })
  }

  const televerserAvecRetry = async (supabase, bucket, path, fichierOriginal, tentatives = 2) => {
    const fichier = await compresserImage(fichierOriginal)
    let derniereErreur = null
    for (let i = 0; i < tentatives; i++) {
      const { error } = await supabase.storage.from(bucket).upload(path, fichier, { upsert: true })
      if (!error) return { error: null }
      derniereErreur = error
      const message = String(error.message || error.statusCode || '')
      const estTemporaire = /50[0-9]|network|fetch/i.test(message)
      if (!estTemporaire || i === tentatives - 1) break
      await new Promise((r) => setTimeout(r, 1500))
    }
    return { error: derniereErreur }
  }

  return { compresserImage, televerserAvecRetry }
}
