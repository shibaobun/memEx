const colors = require('tailwindcss/colors')

module.exports = {
  purge: [
    '../lib/**/*.ex',
    '../lib/**/*.leex',
    '../lib/**/*.eex',
    './js/**/*.js'
  ],
  darkMode: "media",
  theme: {
    colors: {
      transparent: 'transparent',
      current: 'currentColor',
      
      primary: colors.indigo,
      
      black: colors.black,
      white: colors.white,
      gray: colors.trueGray,
      indigo: colors.indigo,
      red: colors.rose,
      yellow: colors.amber,
    },
    extend: {},
  },
  variants: {
    extend: {
      backgroundColor: ['active'],
      borderColor: ['active'],
    },
  },
  plugins: [],
}
