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
      apiBaseUrl: process.env.NUXT_PUBLIC_API_BASE_URL || ''
    }
  },

  vite: {
    server: {
      // Allows testing the app from a phone on the same Wi-Fi during development.
      host: '0.0.0.0'
    }
  }
})
