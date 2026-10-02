function Setup-Tailwind {
    param(
        [string]$TargetDir
    )

    $content = @"
/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    './components/**/*.{js,vue,ts}',
    './layouts/**/*.vue',
    './pages/**/*.vue',
    './plugins/**/*.{js,ts}',
    './app.vue',
    './app/**/*.{js,vue,ts}',
    './error.vue',
    './modules/**/*.{js,vue,ts}'
  ],
  theme: {
    extend: {},
  },
  plugins: [],
}
"@
    Set-Content -Path (Join-Path $TargetDir "tailwind.config.js") -Value $content -Encoding utf8
}
