# DIAGNOSTIC.md — Diagnostic complet du projet RETROUVA

Document généré lors de la préparation à la mise en ligne définitive. Il liste ce qui a été
vérifié, ce qui a été corrigé/ajouté, et ce qu'il reste à faire manuellement avant d'ouvrir le
site au public.

---

## 🔴 1. Sécurité — action obligatoire avant mise en ligne

**Le fichier `.env` livré dans le projet contenait de vraies clés Supabase actives** (URL, clé
`anon`, et clé `service_role`). La clé `service_role` en particulier contourne toutes les
protections de sécurité (RLS) de votre base de données : quiconque la possède peut lire, modifier
ou supprimer n'importe quelle donnée, sans restriction.

**Ce qui a été fait :**
- Le fichier `.env` réel a été retiré de la livraison — il ne doit jamais circuler tel quel.
- Un fichier `.env.example` propre (sans vraies valeurs) a été ajouté à sa place.
- `.gitignore` protège déjà correctement `.env` d'un envoi accidentel sur un dépôt Git.

**Ce qu'il vous reste à faire, avant toute mise en ligne définitive :**
1. Dans le dashboard Supabase → **Project Settings → API**, régénérez (« Reset »/« Roll ») la clé
   `anon` **et** la clé `service_role`.
2. Reportez les nouvelles valeurs dans votre `.env` local (copié depuis `.env.example`) et dans
   les variables d'environnement de votre hébergeur (Vercel : Project Settings → Environment
   Variables) — jamais dans un fichier commis dans un dépôt.
3. Ne renvoyez plus jamais ce fichier `.env` par e-mail, chat ou messagerie une fois vos clés de
   production actives.

---

## 2. Pages manquantes — ajoutées

| Page | Chemin | Rôle |
|---|---|---|
| Politique de cookies | `/cookies` | Détail des cookies utilisés + gestion des préférences |
| Politique de confidentialité | `/politique-de-confidentialite` | Traitement des données personnelles (RGPD / loi ivoirienne n° 2013-450) |
| Conditions générales d'utilisation | `/conditions-utilisation` | Règles d'usage de la plateforme |
| Mentions légales | `/mentions-legales` | Identité de l'éditeur (à compléter, voir §4) |
| Maintenance | `/maintenance` | Affichée automatiquement quand le mode maintenance est activé |
| Erreur / page introuvable | `error.vue` (racine) | Remplace la page 404 par défaut de Nuxt |

Toutes suivent la charte graphique existante (couleurs, typographies, composants `card`, `btn-*`,
mode sombre inclus) — aucune dépendance ajoutée.

---

## 3. Bandeau de consentement aux cookies — ajouté

- `components/CookieConsent.vue` : bandeau « Tout accepter / Refuser / Personnaliser », affiché
  sur toutes les pages via `app.vue`.
- `composables/useCookieConsent.js` : logique de stockage du choix (localStorage), réutilisable.
- Catégorisation :
  - **Nécessaires** (toujours actifs, pas de consentement requis) : connexion, thème, identifiant
    de conversation support.
  - **Confort** (nécessitent un accord) : pop-up d'information (`SitePopup.vue`), vidéo de
    présentation (`IntroVideo.vue`), écran de bienvenue (`OnboardingIntro.vue`) — désactivés si
    l'utilisateur refuse explicitement.
- Aucun cookie publicitaire ou de mesure d'audience tiers n'était présent dans le projet — rien à
  bloquer de ce côté, la page `/cookies` le précise clairement.
- Case à cocher obligatoire « J'accepte les CGU et la politique de confidentialité » ajoutée sur
  `/inscription` (bloque la création de compte tant qu'elle n'est pas cochée).

---

## 4. Mentions légales et CGU — contenu à compléter

Le contenu juridique (CGU, politique de confidentialité, mentions légales) a été rédigé
intégralement, adapté au fonctionnement réel de RETROUVA (déclarations, vérification, dons,
restitution). Il reste des champs `[à compléter]` que seul l'éditeur du site peut renseigner :

- Raison sociale, forme juridique, numéro RCCM, numéro de compte contribuable (NCC)
- Adresse du siège social, e-mail et téléphone de contact
- Nom de l'hébergeur web définitif (Vercel ou autre)
- Date de mise en ligne (pour horodater les CGU/politique de confidentialité)

Ces informations se trouvent dans `pages/mentions-legales.vue`,
`pages/politique-de-confidentialite.vue` et `pages/conditions-utilisation.vue` — recherchez
`[à compléter]` dans ces trois fichiers.

---

## 5. Mode maintenance — ajouté

- Bascule en un clic depuis **`/admin/contenu`** (nouvelle section « Mode maintenance »), avec un
  message optionnel affiché aux visiteurs.
- `middleware/00.maintenance.global.js` : redirige tout le site public vers `/maintenance`
  lorsque le mode est actif. L'administration (`/admin/**`) et les comptes
  administrateur/modérateur restent toujours accessibles, pour pouvoir désactiver la maintenance
  et vérifier le rendu du site pendant les travaux.
- `supabase/migration_24_maintenance.sql` ajoute les deux réglages nécessaires
  (`maintenance_mode`, `maintenance_message`) à une base existante — un nouveau projet exécutant
  `schema.sql` pour la première fois les a déjà.

---

## 6. Référencement (SEO) — ajouté

- `public/robots.txt` et `public/sitemap.xml` créés, avec un domaine `[DOMAINE]` à remplacer une
  fois votre nom de domaine définitif choisi.
- Balises Open Graph / Twitter Card ajoutées dans `nuxt.config.js` pour un meilleur rendu lors du
  partage de liens RETROUVA sur WhatsApp, Facebook, etc.

---

## 7. Vérifications effectuées, sans anomalie détectée

- **Liens internes** : tous les `NuxtLink to="..."` du projet ont été comparés à la liste réelle
  des pages — aucun lien mort.
- **Traceurs tiers** : aucun script Google Analytics, Meta Pixel ou équivalent trouvé dans le
  code — rien à bloquer derrière le consentement cookies au-delà de ce qui est déjà géré.
- **Sécurité des routes serveur** (`server/api/admin/inviter.post.js`,
  `server/api/compte/supprimer.post.js`) : le rôle de l'appelant est systématiquement revérifié en
  base à partir du jeton d'authentification, jamais à partir d'une donnée envoyée par le client —
  bonne pratique déjà en place, aucune correction nécessaire.
- **Build de production** : `nuxt build` exécuté avec succès après l'ensemble des modifications
  (aucune erreur de compilation, aucun import cassé).

---

## 8. Checklist avant mise en ligne définitive

- [ ] Régénérer les clés Supabase (`anon` + `service_role`) — voir §1.
- [ ] Compléter les champs `[à compléter]` des pages légales — voir §4.
- [ ] Exécuter `supabase/migration_24_maintenance.sql` si votre base existait déjà avant cette
      mise à jour (inutile si vous repartez d'un `schema.sql` neuf).
- [ ] Remplacer `[DOMAINE]` dans `public/robots.txt` et `public/sitemap.xml` par votre nom de
      domaine réel.
- [ ] Configurer les variables d'environnement (`SUPABASE_URL`, `SUPABASE_ANON_KEY`,
      `SUPABASE_SERVICE_ROLE_KEY`) chez votre hébergeur (ex. Vercel), jamais en dur dans le code.
- [ ] Vérifier qu'un SMTP est configuré côté Supabase pour l'envoi réel des e-mails (voir README
      §3bis) — sans cela, inscriptions et réinitialisations de mot de passe resteront bloquées.
- [ ] Faire un essai du mode maintenance (`/admin/contenu`) avant le jour J, pour vérifier que le
      message affiché vous convient.
- [ ] `npm install` puis `npm run generate` (ou `npm run build` selon votre hébergeur) pour
      produire la version de production.

---

*Ce fichier peut être supprimé du projet une fois la checklist ci-dessus terminée — il documente
uniquement la préparation à la mise en ligne, pas le fonctionnement courant de l'application.*
