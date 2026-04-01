/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        // AutoWala brand colors - Yellow/Gold Auto-rickshaw Theme
        brand: {
          50: '#FFFBEB',   // Amber 50
          100: '#FEF3C7',  // Amber 100
          200: '#FDE68A',  // Amber 200
          300: '#FCD34D',  // Amber 300
          400: '#FBBF24',  // Amber 400
          500: '#F59E0B',  // Primary Yellow/Gold
          600: '#D97706',  // Amber 600
          700: '#B45309',  // Amber 700
          800: '#92400E',  // Amber 800
          900: '#78350F',  // Amber 900
          950: '#451A03',  // Amber 950
        },
        // Auto-rickshaw inspired accent colors
        auto: {
          yellow: '#F59E0B',
          gold: '#D97706',
          cream: '#FEF3C7',
          black: '#1C1917',
          green: '#16A34A',  // For success states
        },
        // Admin-specific colors with Yellow/Gold theme
        admin: {
          bg: '#FFFBEB',      // Warm cream background
          surface: '#ffffff',
          border: '#FDE68A',   // Light amber border
          text: {
            primary: '#1C1917',
            secondary: '#78350F',
            muted: '#92400E',
          },
          accent: {
            primary: '#F59E0B',  // Yellow/Gold
            secondary: '#D97706',
            success: '#16A34A',
            error: '#DC2626',
          }
        }
      },
      fontFamily: {
        sans: ['Inter', 'system-ui', 'sans-serif'],
      },
      fontSize: {
        'xs': '.75rem',
        'sm': '.875rem',
        'base': '1rem',
        'lg': '1.125rem',
        'xl': '1.25rem',
        '2xl': '1.5rem',
        '3xl': '1.875rem',
        '4xl': '2.25rem',
      },
      boxShadow: {
        'card': '0 1px 3px 0 rgba(0, 0, 0, 0.1), 0 1px 2px -1px rgba(0, 0, 0, 0.1)',
        'card-hover': '0 4px 6px -1px rgba(0, 0, 0, 0.1), 0 2px 4px -2px rgba(0, 0, 0, 0.1)',
        'dropdown': '0 10px 30px rgba(0, 0, 0, 0.12)',
      },
      animation: {
        'fade-in': 'fadeIn 0.5s ease-out',
        'slide-in': 'slideIn 0.3s ease-out',
        'bounce-subtle': 'bounceSubtle 2s infinite',
      },
      keyframes: {
        fadeIn: {
          '0%': { opacity: '0', transform: 'translateY(10px)' },
          '100%': { opacity: '1', transform: 'translateY(0)' },
        },
        slideIn: {
          '0%': { transform: 'translateX(-100%)' },
          '100%': { transform: 'translateX(0)' },
        },
        bounceSubtle: {
          '0%, 100%': { transform: 'translateY(0)' },
          '50%': { transform: 'translateY(-5px)' },
        },
      },
    },
  },
  plugins: [],
}