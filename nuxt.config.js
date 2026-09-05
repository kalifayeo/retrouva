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
        { name: 'apple-mobile-web-app-status-bar-style', content: 'black-translucent' }
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
    public: {
      supabaseUrl: process.env.SUPABASE_URL || '',
      supabaseAnonKey: process.env.SUPABASE_ANON_KEY || '',
      appName: 'RETROUVA'
    }
  },

  vite: {
    server: {
      // Allows testing the app from a phone on the same Wi-Fi during development.
      host: '0.0.0.0'
    }
  }
})
