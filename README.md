# RETROUVA

**Trouver. Connecter. Restituer.**
Plateforme ivoirienne de restitution d'objets et documents importants perdus — web (Nuxt) et mobile (Capacitor).

## Stack

Nuxt.js · Vue.js · Capacitor · JavaScript · Tailwind CSS · Supabase (Auth, PostgreSQL, Storage, Realtime, Edge Functions)

## 1. Installation initiale

```bash
npm install
cp .env.example .env
# → renseigner SUPABASE_URL et SUPABASE_ANON_KEY dans .env
npm run dev
```

L'application est disponible sur `http://localhost:3000`.

## 2. Base de données Supabase — marche à suivre simplifiée

**Cas A — Premier projet Supabase, jamais rien exécuté :**
Dashboard Supabase → **SQL Editor** → collez tout `supabase/schema.sql` → **Run**. C'est tout,
il contient déjà le module admin/CMS.

**Cas B — Vous avez déjà exécuté `schema.sql` une fois** (erreur du type
`type "user_role" already exists` si vous le relancez) :
Dashboard Supabase → **SQL Editor** → collez tout `supabase/migration_02_admin_cms.sql` →
**Run**. Ce fichier n'ajoute que ce qui manque (module admin/CMS) et corrige au passage le profil
administrateur (voir point suivant).

**Devenir administrateur — étape simplifiée (une seule commande) :**
Auparavant il fallait se connecter une première fois avant de pouvoir s'attribuer le rôle, sinon
la commande ne trouvait aucune ligne à modifier ("0 ligne modifiée"). C'est corrigé : un
déclencheur crée maintenant automatiquement votre profil dès l'inscription, et
`migration_02_admin_cms.sql` répare aussi les comptes déjà créés avant ce correctif. Après avoir
exécuté ce fichier, la dernière ligne du script affiche directement votre rôle — vérifiez qu'elle
indique bien `super_administrateur`. Si besoin, relancez seule cette commande (adaptez l'e-mail) :
```sql
update profiles set role = 'super_administrateur'
where id = (select id from auth.users where email = 'votre-email@exemple.com');
```

**Créer les buckets de stockage (une fois) :**
Dashboard Supabase → **Storage** → **New bucket**, créez `objets-trouves` (photos des objets) et
`site-media` (images des bannières/pop-up/événements) — les deux en public en lecture.

**⚠️ Étape indispensable, souvent oubliée : les politiques d'upload.**
Rendre un bucket "Public" dans le dashboard ne contrôle que la **lecture** des fichiers. Sans
politiques explicites, **personne ne peut envoyer de fichier**, pas même un administrateur —
vous obtiendrez l'erreur `new row violates row-level security policy`. Exécutez donc aussi
`supabase/migration_08_politiques_storage.sql` dans le SQL Editor (après avoir créé les deux
buckets ci-dessus).

**Base déjà en place et à jour jusqu'à la migration 19 ?** Exécutez en plus, dans l'ordre,
`supabase/migration_20_dons_video_badge_pub.sql` puis
`supabase/migration_21_support_chat_et_numeros_dons.sql` — ils ajoutent les dons, la vidéo de
première connexion, le chat de support et la notification de badge confiance décrits plus bas.
Un nouveau projet qui exécute `schema.sql` pour la première fois a déjà tout cela d'office.

### Nouveautés — dons, chat support, publicité, vidéo d'accueil

- **`/don`** propose désormais un vrai parcours de don (montant + moyen de paiement + coordonnées
  facultatives) et enregistre chaque don dans `/admin/dons`, où vous gérez aussi les numéros
  Orange Money / MTN Mobile Money / Wave affichés. Aucune passerelle de paiement réelle n'étant
  connectée, chaque don reste une **intention** que vous confirmez manuellement après réception.
- **Bouton flottant (bas à droite, sur tout le site)** : WhatsApp (numéro dans
  `/admin/contenu`), retour en haut de page, et chat de support géré depuis `/admin/support`.
- **Vidéo de présentation** à la première connexion sur un appareil, activable et configurable
  dans `/admin/introduction` (avant ou après les diapositives existantes).
- **Bannières et pop-up** acceptent maintenant un nom et un contact d'entreprise, pour identifier
  clairement une publicité payée par un partenaire.
- **Badge confiance** : une notification (pop-up + `/notifications`) prévient désormais
  l'utilisateur dès que son profil devient complet — corrigé au passage pour les villes hors
  Abidjan, qui ne pouvaient jusqu'ici jamais l'atteindre.

## 3. Administration réelle (rôles, contenu, bannières, pop-up, événements)

L'administration a maintenant sa **propre page de connexion**, séparée du site public :
**`/admin/connexion`**. Elle est protégée par rôle réel : il faut un compte avec le rôle
`administrateur` ou `super_administrateur` dans la table `profiles`. Toute page `/admin/**`
redirige automatiquement vers `/admin/connexion` si vous n'êtes pas connecté, ou vers
`/admin/connexion?denied=1` (avec un message clair) si votre compte n'a pas les droits.

L'admin se connecte **par mot de passe**, pas par e-mail — c'est l'usage normal pour un compte
d'équipe. Si votre compte a été créé via la connexion par e-mail du site (`/connexion`), il n'a
pas encore de mot de passe : définissez-en un une fois, dans Supabase :
Dashboard Supabase → **Authentication → Users** → cliquez sur votre compte → **Reset password**
(ou équivalent selon la version de l'interface) → saisissez un mot de passe. Vous pouvez ensuite
vous connecter sur `/admin/connexion` avec cet e-mail + ce mot de passe.

**Ce que l'admin permet aujourd'hui :**
- `/admin/utilisateurs` — voir tous les comptes et changer leur rôle.
- `/admin/contenu` — modifier les textes de la page d'accueil sans toucher au code.
- `/admin/bannieres` — bannières publicitaires/informatives (image + lien), par zone d'affichage.
- `/admin/popups` — pop-up affiché une fois par visite (promo, information, alerte).
- `/admin/evenements` — journées de restitution, campagnes, séances.
- `/admin` — tableau de bord avec compteurs réels (déclarations, correspondances, signalements).

Reste à connecter pour une V1 complète : modération des signalements, messagerie temps réel,
calcul du vrai score de correspondance (les résultats de `/resultats` sont encore des données de
démonstration).

**Site public — expérience une fois connecté.** Le bouton « Se connecter » du header est remplacé
par les initiales de l'utilisateur, avec un menu déroulant (Mon profil, Mes recherches, Mes objets
trouvés, Messagerie, Administration si applicable, Se déconnecter) — sur desktop et mobile.

## 3quater. Inscription professionnelle (infos + vérification e-mail + mot de passe)

Le parcours a changé : ce n'est plus un code à chaque connexion, mais un vrai compte.

- **`/inscription`** — l'utilisateur renseigne nom, téléphone, ville, commune, e-mail, mot de
  passe. Ces informations sont automatiquement copiées dans son profil (déclencheur SQL).
- **`/verifier-email`** — après l'inscription, un code de vérification est envoyé par e-mail ;
  une fois saisi, le compte est activé.
- **`/connexion`** — désormais e-mail + mot de passe uniquement (le mode "normal" ensuite).
- **`/mot-de-passe-oublie`** et **`/reinitialiser-mot-de-passe`** — récupération de compte
  classique par e-mail.

**Exécuter la migration** : Dashboard Supabase → SQL Editor → collez
`supabase/migration_04_inscription_et_fond.sql` → **Run**.

**Réglage important — réactivez "Confirm email" :**
Si vous l'aviez désactivé plus tôt pour tester (voir section 3bis, maintenant obsolète), remettez-le
: Dashboard Supabase → **Authentication → Providers → Email** → cochez **Confirm email**. Sans ça,
Supabase ne demande plus de vérification et l'étape `/verifier-email` est inutile.

**Personnaliser le message de vérification (recommandé)** — comme pour le lien de connexion
précédent, l'e-mail par défaut ne montre qu'un lien, pas de code. Dashboard Supabase →
**Authentication → Email Templates → Confirm signup** → onglet **Source** (nécessite le SMTP
configuré, voir section suivante) → ajoutez `{{ .Token }}` bien visible dans le corps du message,
par exemple :
```html
<p style="font-size: 32px; font-weight: bold; letter-spacing: 8px; text-align: center; padding: 16px; background: #EAF3EC; border-radius: 12px;">
  {{ .Token }}
</p>
```
Faites la même chose pour le modèle **Reset Password** (mot de passe oublié).

## 3bis. Configurer un SMTP (obligatoire pour un vrai envoi d'e-mails)

Le service e-mail interne de Supabase est très limité (quelques envois par heure, et il est
impossible d'y personnaliser les messages sans SMTP externe). Pour un site utilisable par de vrais
utilisateurs, configurez un fournisseur gratuit :

- **Resend** (resend.com, 3000 e-mails/mois gratuits) — simple, mais `onboarding@resend.dev` ne
  peut envoyer qu'à l'adresse du compte Resend tant qu'aucun domaine n'est vérifié.
- **Brevo** (brevo.com, 300/jour gratuits) — permet de vérifier une simple adresse e-mail (pas tout
  un domaine) et d'envoyer ensuite à n'importe qui, ce qui est plus pratique en phase de test.

Dashboard Supabase → **Project Settings → Auth → SMTP Settings** → activez et renseignez les
identifiants de votre fournisseur.

## 3ter. Moteur de correspondance automatique (matching)

Le calcul du score de correspondance est fait **directement en base de données** (fonctions SQL +
déclencheurs), pas besoin de serveur ni de tâche planifiée séparée.

**À exécuter une fois** dans Supabase → SQL Editor : collez tout `supabase/migration_03_matching.sql`
→ **Run**. (Si vous partez d'une base toute neuve, `schema.sql` contient déjà ce module, inutile
de rejouer la migration séparément.)

**Comment ça marche :**
- Dès qu'une déclaration perdue ou trouvée est créée, un déclencheur calcule automatiquement le
  score avec toutes les déclarations compatibles (même type d'objet obligatoire).
- **Score** : même ville (40 pts) + même commune (20 pts) + proximité des dates (jusqu'à 40 pts
  selon l'écart en jours). Un objet trouvé n'est comparé que s'il est dans la même ville, avec un
  écart de dates de 60 jours maximum.
- À partir de 70%, la déclaration passe automatiquement au statut « correspondance » et le
  propriétaire reçoit une notification réelle (visible dans `/notifications`).
- Les résultats sur `/resultats` et `/resultats/:id` viennent maintenant de la vraie table
  `matches`, plus de données de démonstration.

Le script exécute aussi un rattrapage pour les déclarations déjà présentes dans votre base avant
cette migration.

## 4. Mobile avec Capacitor

```bash
# Ajouter les plateformes (une seule fois)
npx cap add android
npx cap add ios

# Générer le build web statique + synchroniser
npm run cap:sync

# Ouvrir dans Android Studio / Xcode
npm run cap:android
npm run cap:ios
```

`nuxt generate` produit un build statique dans `.output/public`, utilisé par Capacitor comme `webDir`
(voir `capacitor.config.json`). L'app est conçue mobile-first : barre de navigation basse type app
native, zones tactiles ≥ 44px, gestion des zones sûres (`safe-area-inset`), formulaires en plusieurs
étapes optimisés pour petit écran.

## 4. Procédure de mise à jour (Windows / PowerShell)

Pour intégrer un nouveau zip généré dans le dossier `Retrouva-nouveau`, en remplaçant un dossier
précis du projet (exemple avec `app` — adapter selon le dossier livré : `pages`, `components`, etc.) :

```powershell
# 1. Remplacer le dossier concerné
Remove-Item -Recurse -Force "C:\Users\kalif\Desktop\retrouva\pages" -ErrorAction SilentlyContinue
Copy-Item -Recurse -Force "C:\Users\kalif\Desktop\Retrouva-nouveau\retrouva\pages" "C:\Users\kalif\Desktop\retrouva\pages"

# 2. Se placer dans le projet, vider le cache et relancer
Set-Location "C:\Users\kalif\Desktop\retrouva"
Remove-Item -Recurse -Force ".nuxt" -ErrorAction SilentlyContinue
npm install
npm run dev
```

Répétez l'étape 1 pour chaque dossier livré dans un nouveau zip (`components`, `composables`,
`supabase`, etc.), puis relancez toujours l'étape 2 une seule fois à la fin.

## 5. Structure du projet

```
retrouva/
├── assets/css/main.css        # styles globaux, tokens de marque
├── components/                 # AppHeader, AppFooter, IconTab, ObjectTypeCard…
├── composables/                 # useSupabase, useObjectTypes
├── layouts/default.vue         # header responsive + barre de navigation mobile
├── pages/                       # toutes les routes (accueil, perdu, trouvé, admin…)
├── plugins/supabase.client.js  # client Supabase injecté globalement
├── public/logo.png             # logo RETROUVA
├── supabase/schema.sql         # schéma PostgreSQL + politiques RLS
├── capacitor.config.json
├── nuxt.config.js
└── tailwind.config.js          # palette de marque (forest / savane / ivoire)
```

## 6. Identité visuelle

Palette dérivée du logo : vert forêt profond (`forest-800 #0B3D24`), orange savane
(`savane-500 #F5901E`), fond ivoire (`ivoire-100 #FBF8F2`). Typographies : **Sora** (titres) /
**Inter** (texte courant).

## 7. Sécurité

Aucune donnée sensible (numéro complet de document ou de carte bancaire) n'est jamais exposée
publiquement. Voir `supabase/schema.sql` pour les politiques RLS et `/securite` dans l'app pour le
détail des engagements produits. Toute logique de vérification de propriété doit être déplacée en
Edge Function côté serveur avant mise en production.

## 8. Questions fréquentes du créateur

**Dois-je exécuter `supabase/schema.sql` ?**
Oui, obligatoirement, une seule fois (puis à nouveau si vous ajoutez des tables). Sans cela,
aucune table n'existe dans votre projet Supabase et rien ne peut être enregistré. Dashboard
Supabase → **SQL Editor** → coller tout le contenu du fichier → **Run**.

**Créer aussi un bucket de stockage** (pour les photos d'objets trouvés) :
Dashboard Supabase → **Storage** → **New bucket** → nommez-le `objets-trouves` → rendez-le public
en lecture (les photos ne doivent jamais contenir d'information sensible visible).

**Où sont stockées les données ?**
Dans votre propre projet Supabase (base PostgreSQL hébergée par Supabase, région à choisir à la
création du projet — ex. Europe). Vous en êtes propriétaire à 100 %. Le plan gratuit Supabase
inclut 500 Mo de base de données et 1 Go de stockage fichiers, largement suffisant pour démarrer.

**Le site est gratuit, qu'est-ce que je gagne ?**
Un bouton **« Faire un don »** a été ajouté (menu principal + pied de page + page `/don`) avec des
emplacements pour vos numéros Mobile Money / Wave. Remplacez les valeurs d'exemple dans
`pages/don.vue` par vos vrais numéros avant mise en ligne. À terme, un espace partenaire payant ou
des dons ponctuels des utilisateurs peuvent couvrir vos coûts (hébergement, SMS, modération).

**Pourquoi je ne reçois pas de code par SMS à la connexion ?**
La connexion par téléphone via Supabase nécessite un fournisseur SMS **payant** (Twilio,
MessageBird, Vonage…) à configurer dans Dashboard Supabase → Authentication → Providers → Phone.
Tant qu'aucun fournisseur n'est branché, aucun SMS ne part, quel que soit le code du site.
**Correction apportée :** la page `/connexion` utilise maintenant une connexion par **e-mail avec
code à 6 chiffres**, gratuite et gérée nativement par Supabase (aucune carte bancaire requise pour
démarrer). Vous pourrez réactiver le SMS plus tard en branchant un fournisseur.

**Le site paraît petit et centré sur grand écran / la page d'accueil n'est pas responsive.**
Corrigé : le conteneur principal (`container-app`) est passé de 1152px à 1600px de large maximum
avec des marges qui s'adaptent progressivement (`sm`, `lg`, `xl`, `2xl`), et les titres/images de
la page d'accueil s'agrandissent sur grand écran (`xl:`). Vérifiez après un `npm run dev` +
rechargement complet (Ctrl+F5) pour éviter un ancien CSS mis en cache.

**Les cartes d'objets (CNI, carte étudiant…) n'ont pas d'image.**
Corrigé : vos images (`img_retrouva.zip`) sont intégrées dans `public/objets/` et affichées sur
les cartes de type d'objet (accueil, page « perdu », page « trouvé ») via
`composables/useObjectTypes.js`.

**Le site n'est pas dynamique : je ne vois pas mon espace pour mes déclarations.**
Corrigé en partie : une vraie authentification (e-mail + code) est branchée, et les pages
`/profil`, `/mes-recherches`, `/mes-objets-trouves` lisent maintenant les vraies données de
l'utilisateur connecté dans Supabase (tables `lost_reports` / `found_reports`). Les formulaires
`/perdu` et `/trouve` enregistrent réellement une déclaration liée à votre compte. Restent à
implémenter : la messagerie, les notifications et le calcul du score de correspondance (voir
section « Prochaines étapes »).

**Il n'y a pas de page admin.**
Elle existe déjà : `/admin` (fichier `pages/admin/index.vue`), accessible depuis le menu
« Administration » dans `/profil`. Elle n'est pour l'instant pas connectée à de vraies données ni
protégée par rôle — voir « Prochaines étapes » ci-dessous pour la sécuriser avant mise en ligne
publique.

**Je reçois un e-mail "Your sign-in link" (lien) et pas un code, et cliquer dessus ne me connecte
pas.**
Deux choses à faire :

1. **Autoriser l'adresse de retour dans Supabase** (obligatoire, sinon le lien ne connectera
   jamais). Dashboard Supabase → **Authentication → URL Configuration** → dans **Redirect URLs**,
   ajoutez :
   ```
   http://localhost:3000/**
   ```
   (et plus tard l'URL de votre site en ligne, ex. `https://retrouva.ci/**`). Sans cette étape,
   Supabase refuse la redirection et le lien ne fait rien.
2. **Corrigé côté code** : le clic sur le lien reconnecte désormais automatiquement (le paramètre
   technique `detectSessionInUrl` était désactivé par erreur). La page `/connexion` détecte la
   session et vous redirige seule vers `/profil`.

Si vous préférez un vrai **code à 6 chiffres** plutôt qu'un lien à cliquer (meilleure expérience
mobile), modifiez le modèle d'e-mail : Dashboard Supabase → **Authentication → Email Templates →
Magic Link**, remplacez le contenu du lien par `{{ .Token }}` pour afficher le code au lieu de
l'URL de confirmation. Le formulaire `/connexion` accepte déjà la saisie de ce code.

**Erreur "500 — Cannot read properties of undefined (reading 'auth')" au démarrage.**
Cela signifie que le fichier `.env` n'existe pas ou n'a pas de vraies clés Supabase (le zip ne
contient jamais votre `.env`, pour ne pas exposer vos clés). Corrigé pour ne plus planter :
désormais un bandeau orange s'affiche en haut du site tant que `.env` n'est pas renseigné, au lieu
d'une page d'erreur 500. Pour résoudre définitivement :
```bash
cp .env.example .env
# puis ouvrez .env et remplacez les deux valeurs par celles de
# Dashboard Supabase > Project Settings > API (Project URL et anon public key)
```
Puis relancez `npm run dev` (ou arrêtez le serveur avec Ctrl+C et relancez-le — un `.env` modifié
n'est pris en compte qu'au redémarrage).

## 9. Prochaines étapes suggérées

1. Brancher les formulaires (`/perdu`, `/trouve`) sur Supabase (insert réel + Storage pour les photos).
2. Implémenter la fonction de matching (score) en Edge Function.
3. Authentification réelle par OTP téléphone (Supabase Auth + provider SMS).
4. Dashboard admin connecté aux données réelles.
5. Icônes et splash screens natifs (Android/iOS) à générer à partir de `public/logo.png`.
