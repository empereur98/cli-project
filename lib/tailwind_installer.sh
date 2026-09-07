#!/bin/bash

setup_tailwind() {
  local target_dir="$1"

  cat << 'EOF' > "$target_dir/tailwind.config.js"
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
EOF
}
