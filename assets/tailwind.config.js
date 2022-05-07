const colors = require('tailwindcss/colors')

module.exports = {
  content: [
    '../lib/**/*.{ex,heex,leex,eex}',
    './js/**/*.js'
  ],
  theme: {
    colors: {
      transparent: 'transparent',
      current: 'currentColor',
      primary: colors.indigo,
      black: colors.black,
      white: colors.white,
      gray: colors.neutral,
      indigo: colors.indigo,
      red: colors.rose,
      yellow: colors.amber
    },
    extend: {
      spacing: {
        128: '32rem',
        192: '48rem',
        256: '64rem'
      },
      minWidth: {
        4: '1rem',
        8: '2rem',
        12: '3rem',
        16: '4rem',
        20: '8rem'
      },
      maxWidth: {
        4: '1rem',
        8: '2rem',
        12: '3rem',
        16: '4rem',
        20: '8rem'
      }
    }
  },
  plugins: []
}
