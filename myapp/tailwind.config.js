module.exports = {
  content: [
    "./app/views/**/*.html.erb",
    "./app/helpers/**/*.rb",
    "./app/assets/stylesheets/**/*.css",
    "./app/javascript/**/*.js"
  ],
  plugins: [
    require("@tailwindcss/typography"),
    require("@tailwindcss/forms")({
      // strategy: "base" // only generate global styles
      // strategy: "class" // only generate classes
    }),
    require("@tailwindcss/line-clamp"),
    require("@tailwindcss/aspect-ratio")
  ]
}
