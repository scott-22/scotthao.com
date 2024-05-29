/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    "./templates/{static,dynamic}/*.lisp",
    "./templates/*.lisp",
  ],
  theme: {
    extend: {},
  },
  plugins: [],
}
