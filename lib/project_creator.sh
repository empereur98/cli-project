#!/bin/bash

create_project() {
  local project_name="$1"
  local cli_dir="$2"

  if [ -z "$project_name" ]; then
    echo -e "\033[1;31m[ERROR] Project name is required.\033[0m"
    echo "Usage: ./nx create <project_name>"
    exit 1
  fi

  local target_dir="./$project_name"

  if [ -d "$target_dir" ]; then
    echo -e "\033[1;31m[ERROR] Directory '$target_dir' already exists. Aborting.\033[0m"
    exit 1
  fi

  echo -e "\033[1;34m[INFO] Creating Nuxt project '$project_name' pre-configured with Tailwind CSS...\033[0m"

  mkdir -p "$target_dir/app"
  mkdir -p "$target_dir/modules"

  # Scaffold project configuration files
  sed "s/{{MODULE_NAME}}/$project_name/g" "$cli_dir/templates/package_json.template" > "$target_dir/package.json"
  cp "$cli_dir/templates/nuxt_config_project.template" "$target_dir/nuxt.config.ts" 2>/dev/null || \
    cp "$cli_dir/templates/nuxt_config.template" "$target_dir/nuxt.config.ts"
  echo '{"extends": "./.nuxt/tsconfig.json"}' > "$target_dir/tsconfig.json"
  cp "$cli_dir/templates/gitignore.template" "$target_dir/.gitignore"

  # Scaffold nx.config.json registry
  sed "s/{{PROJECT_NAME}}/$project_name/g" "$cli_dir/templates/nx_config_json.template" > "$target_dir/nx.config.json"

  # Scaffold default app.vue starter
  cp "$cli_dir/templates/app_vue_project.template" "$target_dir/app/app.vue" 2>/dev/null || \
    sed "s/{{MODULE_NAME}}/$project_name/g" "$cli_dir/templates/app_vue.template" > "$target_dir/app/app.vue"

  # Setup Tailwind config
  setup_tailwind "$target_dir"

  # Embed `./nx` wrapper & nxt-cli directory (Maven Wrapper paradigm)
  cp -r "$cli_dir" "$target_dir/nxt-cli"
  cp "$cli_dir/nx" "$target_dir/nx"
  cp "$cli_dir/nx.cmd" "$target_dir/nx.cmd" 2>/dev/null || true
  cp "$cli_dir/nx.ps1" "$target_dir/nx.ps1" 2>/dev/null || true
  chmod +x "$target_dir/nx"

  # Setup Git repository interactively
  setup_git "$target_dir" "$cli_dir/templates/gitignore.template"

  # Install dependencies & prepare Nuxt with progress bar
  run_with_progress "Installing dependencies for '$project_name'" bash -c "cd '$target_dir' && npm install"
  run_with_progress "Generating Nuxt TypeScript declarations (nuxt prepare)" bash -c "cd '$target_dir' && npx -y nuxt prepare"

  echo ""
  echo -e "\033[1;32m[SUCCESS] Nuxt project '$project_name' created with embedded ./nx wrapper.\033[0m"
  echo -e "\033[0;36m[NEXT STEPS]\033[0m"
  echo -e "  \033[1;37mcd $target_dir\033[0m"
  echo -e "  \033[1;37mnpm run dev\033[0m"
  echo ""
}
