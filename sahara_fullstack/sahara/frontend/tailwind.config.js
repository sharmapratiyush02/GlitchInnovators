/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    './index.html',
    './*.{js,jsx,ts,tsx}',
  ],
  theme: {
    extend: {
      colors: {
        sand:  { DEFAULT: '#F5E6CC', 2: '#EDD9B8', 3: '#E8C99A' },
        ember: { DEFAULT: '#B5652A', 2: '#D4956A', 3: '#8B3A12' },
        dark:  '#3D1F0A',
        mid:   '#8B6E4E',
        dim:   '#C4A882',
        cream: '#FDFAF5',
      },
      fontFamily: {
        display: ['Cormorant Garamond', 'serif'],
        body:    ['Sora', 'sans-serif'],
        mono:    ['DM Mono', 'monospace'],
      },
    },
  },
  plugins: [],
}