export default defineNuxtConfig({
  compatibilityDate: '2024-09-01',
  devtools: { enabled: false },

  modules: [
    '@nuxtjs/tailwindcss',
    '@vueuse/nuxt'
  ],

  // Capacitor packages the app as a static bundle served from the device (capacitor://).
  // SPA target keeps routing/asset resolution simple and reliable inside a WebView.
  ssr: false,

  app: {
    head: {
      title: 'RETROUVA — Trouver. Connecter. Restituer.',
      htmlAttrs: { lang: 'fr' },
      meta: [
        { charset: 'utf-8' },
        { name: 'viewport', content: 'width=device-width, initial-scale=1, viewport-fit=cover, maximum-scale=1' },
        { name: 'theme-color', content: '#0B3D24' },
        { name: 'description', content: "RETROUVA est la plateforme ivoirienne qui aide à retrouver, connecter et restituer les objets et documents importants perdus en Côte d'Ivoire." },
        { name: 'mobile-web-app-capable', content: 'yes' },
        { name: 'apple-mobile-web-app-capable', content: 'yes' },
        { name: 'apple-mobile-web-app-status-bar-style', content: 'black-translucent' },
        // Partage sur les réseaux sociaux (Open Graph / Twitter Card).
        // Remplacez og:url par le domaine réel une fois le site en ligne.
        { property: 'og:type', content: 'website' },
        { property: 'og:site_name', content: 'RETROUVA' },
        { property: 'og:title', content: 'RETROUVA — Trouver. Connecter. Restituer.' },
        { property: 'og:description', content: "RETROUVA est la plateforme ivoirienne qui aide à retrouver, connecter et restituer les objets et documents importants perdus en Côte d'Ivoire." },
        { property: 'og:image', content: '/logo.png' },
        { name: 'twitter:card', content: 'summary' },
        { name: 'twitter:title', content: 'RETROUVA — Trouver. Connecter. Restituer.' },
        { name: 'twitter:description', content: "RETROUVA est la plateforme ivoirienne qui aide à retrouver, connecter et restituer les objets et documents importants perdus en Côte d'Ivoire." },
        { name: 'twitter:image', content: '/logo.png' }
      ],
      link: [
        { rel: 'icon', type: 'image/png', href: '/logo.png' },
        { rel: 'apple-touch-icon', href: '/logo.png' },
        { rel: 'preconnect', href: 'https://fonts.googleapis.com' },
        { rel: 'preconnect', href: 'https://fonts.gstatic.com', crossorigin: '' },
        { rel: 'stylesheet', href: 'https://fonts.googleapis.com/css2?family=Sora:wght@400;500;600;700;800&family=Inter:wght@400;500;600;700&display=swap' }
      ]
    }
  },

  css: ['~/assets/css/main.css'],

  runtimeConfig: {
    // Clé PRIVÉE — jamais exposée au navigateur (absente de "public").
    // Utilisée uniquement par les routes server/api/** (suppression de
    // compte, invitation d'administrateur). À renseigner dans .env et,
    // en production, dans les variables d'environnement Vercel.
    supabaseServiceRoleKey: process.env.SUPABASE_SERVICE_ROLE_KEY || '',

    // --- Paiements en ligne (page /don) — clés PRIVÉES, jamais exposées au
    // navigateur, utilisées uniquement par server/api/dons/**. Laissez vide
    // tant que vous n'avez pas reçu vos identifiants marchand : la page de
    // don continue de fonctionner en mode "instructions manuelles" dans ce
    // cas (numéro à copier / USSD), sans aucune régression.
    orangeMoney: {
      // Developer > mes applications > votre appli "Orange Money Web Payment"
      clientId: process.env.ORANGE_MONEY_CLIENT_ID || '',
      clientSecret: process.env.ORANGE_MONEY_CLIENT_SECRET || '',
      // Fourni par Orange lors de l'activation du compte marchand
      merchantKey: process.env.ORANGE_MONEY_MERCHANT_KEY || ''
    },
    mtnMomo: {
      // Portail momodeveloper.mtn.com > votre abonnement "Collections"
      subscriptionKey: process.env.MTN_MOMO_SUBSCRIPTION_KEY || '',
      apiUser: process.env.MTN_MOMO_API_USER || '',
      apiKey: process.env.MTN_MOMO_API_KEY || '',
      // 'sandbox' en test, puis l'identifiant fourni par MTN en production
      targetEnvironment: process.env.MTN_MOMO_TARGET_ENVIRONMENT || 'sandbox',
      baseUrl: process.env.MTN_MOMO_BASE_URL || 'https://sandbox.momodeveloper.mtn.com'
    },
    wave: {
      // Wave Business Portal > Développeur > Clés API
      apiKey: process.env.WAVE_API_KEY || '',
      // Wave Business Portal > Développeur > Clés API > activer "request
      // signing" sur la clé : le secret généré sert à vérifier que les
      // webhooks reçus sur /api/dons/wave-webhook viennent bien de Wave.
      webhookSecret: process.env.WAVE_WEBHOOK_SECRET || ''
    },

    // --- Reçu de don par e-mail (server/utils/envoyerEmail.js) — clés
    // PRIVÉES. Tant qu'elles sont vides, aucun e-mail n'est envoyé (le don
    // reste confirmé normalement, seul le reçu automatique est sauté).
    resend: {
      apiKey: process.env.RESEND_API_KEY || '',
      from: process.env.RESEND_FROM_EMAIL || ''
    },

    // --- Reçu de don par SMS (server/utils/envoyerSms.js) — passerelle
    // générique, adaptez l'URL à votre fournisseur. Vide = pas de SMS.
    sms: {
      apiUrl: process.env.SMS_API_URL || '',
      apiKey: process.env.SMS_API_KEY || '',
      sender: process.env.SMS_SENDER || 'RETROUVA'
    },

    // --- Notifications push réelles (server/utils/envoyerPush.js), pour
    // relier la dépendance @capacitor/push-notifications à un vrai envoi
    // Firebase Cloud Messaging. Collez ici le JSON complet du compte de
    // service (Console Firebase > Paramètres du projet > Comptes de
    // service > Générer une nouvelle clé privée) sur une seule ligne. Vide
    // = les jetons d'appareil sont bien enregistrés (voir
    // composables/usePushNotifications.js) mais aucun push n'est envoyé —
    // seule la notification in-app habituelle (cloche du header) l'est.
    firebase: {
      serviceAccountJson: process.env.FIREBASE_SERVICE_ACCOUNT_JSON || ''
    },

    public: {
      supabaseUrl: process.env.SUPABASE_URL || '',
      supabaseAnonKey: process.env.SUPABASE_ANON_KEY || '',
      appName: 'RETROUVA',
      // Base des appels vers /api/** (server/api). Laissez vide pour le
      // site web (les appels relatifs suffisent, l'API est sur le même
      // domaine). Pour l'app mobile Capacitor, définissez cette variable
      // à l'URL de production avant "npm run cap:sync" — ex. dans .env :
      // NUXT_PUBLIC_API_BASE_URL=https://retrouva.vercel.app
      // (l'app packagée n'est pas servie depuis ce domaine, donc un appel
      // relatif "/api/..." ne trouverait rien).
      apiBaseUrl: process.env.NUXT_PUBLIC_API_BASE_URL || '',
      // Indicateurs non sensibles (aucune clé ici) permettant à la page
      // /don de savoir quels boutons "Payer en ligne" afficher, sans avoir
      // à interroger le serveur pour le découvrir.
      paiementsActifs: {
        orange: Boolean(process.env.ORANGE_MONEY_CLIENT_ID && process.env.ORANGE_MONEY_CLIENT_SECRET && process.env.ORANGE_MONEY_MERCHANT_KEY),
        mtn: Boolean(process.env.MTN_MOMO_SUBSCRIPTION_KEY && process.env.MTN_MOMO_API_USER && process.env.MTN_MOMO_API_KEY),
        wave: Boolean(process.env.WAVE_API_KEY)
      }
    }
  },

  vite: {
    server: {
      // Allows testing the app from a phone on the same Wi-Fi during development.
      host: '0.0.0.0'
    }
  }
})
