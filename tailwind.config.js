/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    './templates/{static,dynamic}/**/*.lisp',
    './templates/*.lisp',
  ],
  safelist: ['hl-chroma'],
  theme: {
    extend: {},
    fontFamily: {
      'display': ['"Open Sans"', 'sans-serif'],
      'emphasis': ['Georgia', 'serif'],
      'mono': ['ui-monospace', 'monospace'],
    }
  },
  plugins: [],
}
