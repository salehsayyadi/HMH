/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        brand: {
          primary: '#006B52',
          dark: '#004D3B',
          emerald: '#008866',
          secondary: '#10A77D',
          pastel: '#DDF4E8',
          light: '#EFF9F3',
          bg: '#F4FAF7',
          border: '#D9E9E1',
          text: '#173A31',
          muted: '#71867E',
        },
        res: {
          blue: '#DCEBFF',
          blueText: '#1554A3',
          red: '#FDE7EA',
          redText: '#B42335',
          gray: '#E8ECEE',
          grayText: '#68737A',
        }
      },
      fontFamily: {
        sans: ['Vazirmatn', 'Tahoma', 'sans-serif'],
      },
      borderRadius: {
        'card': '20px',
        'modal': '24px',
        'btn': '14px',
        'input': '12px',
      },
      boxShadow: {
        'soft': '0 4px 20px -2px rgba(0, 107, 82, 0.06)',
        'card': '0 8px 30px -4px rgba(0, 77, 59, 0.08)',
        'modal': '0 20px 50px -10px rgba(0, 77, 59, 0.25)',
        'glow': '0 0 15px rgba(16, 167, 125, 0.3)',
      }
    },
  },
  plugins: [],
}
