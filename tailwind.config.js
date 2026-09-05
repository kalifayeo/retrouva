/** @type {import('tailwindcss').Config} */
export default {
  darkMode: 'class',
  content: [
    './components/**/*.{js,vue,ts}',
    './layouts/**/*.vue',
    './pages/**/*.vue',
    './plugins/**/*.{js,ts}',
    './app.vue',
    './error.vue'
  ],
  theme: {
    extend: {
      colors: {
        // Palette extraite du logo RETROUVA (pin dégradé orange -> vert, badge vert forêt)
        forest: {
          50: '#EAF3EC',
          100: '#CBE3D1',
          200: '#98C7A5',
          300: '#5FA574',
          400: '#357E4E',
          500: '#1F5E37',
          600: '#164A2A',
          700: '#0F3A21',
          800: '#0B3D24', // vert profond — texte "RETROUV", badge
          900: '#082A18'
        },
        savane: {
          50: '#FFF6E9',
          100: '#FFE9C6',
          200: '#FFD08A',
          300: '#FDB44B',
          400: '#FB9F27',
          500: '#F5901E', // orange — "VA", cœur du pin
          600: '#DE7A0F',
          700: '#B4610C',
          800: '#8A4A0A',
          900: '#5F3307'
        },
        ivoire: {
          50: '#FFFDF9',
          100: '#FBF8F2', // fond crème principal
          200: '#F3EEE2'
        },
        ink: '#0E1F15'
      },
      fontFamily: {
        display: ['Sora', 'ui-sans-serif', 'system-ui', 'sans-serif'],
        body: ['Inter', 'ui-sans-serif', 'system-ui', 'sans-serif']
      },
      backgroundImage: {
        'brand-gradient': 'linear-gradient(135deg, #F5901E 0%, #DE7A0F 22%, #5FA574 62%, #0F3A21 100%)',
        'brand-gradient-soft': 'linear-gradient(135deg, #FFF6E9 0%, #EAF3EC 100%)'
      },
      boxShadow: {
        card: '0 2px 10px rgba(11, 61, 36, 0.06)',
        'card-hover': '0 12px 28px rgba(11, 61, 36, 0.14)',
        floating: '0 18px 40px rgba(11, 61, 36, 0.18)'
      },
      borderRadius: {
        xl2: '1.25rem'
      },
      spacing: {
        'safe-top': 'env(safe-area-inset-top)',
        'safe-bottom': 'env(safe-area-inset-bottom)'
      }
    }
  },
  plugins: []
}
