#!/bin/bash

create_module() {
  local module_name="$1"
  local cli_dir="$2"
  local config_key=$(echo "$module_name" | sed 's/-/_/g')

  if [ -z "$module_name" ]; then
    echo -e "\033[1;31m[ERROR] Module name is required.\033[0m"
    echo "Usage: ./nx -m <module_name>"
    exit 1
  fi

  local is_inside_nuxt=false
  local target_dir="./$module_name"
  local tsconfig_extends="./.nuxt/tsconfig.json"

  if [ -f "./nuxt.config.ts" ] || [ -f "./nuxt.config.js" ]; then
    is_inside_nuxt=true
    target_dir="./modules/$module_name"
    tsconfig_extends="../../.nuxt/tsconfig.json"
  fi

  if [ -d "$target_dir" ]; then
    echo -e "\033[1;31m[ERROR] Directory '$target_dir' already exists. Aborting.\033[0m"
    exit 1
  fi

  echo -e "\033[1;34m[INFO] Scaffolding autonomous module '$module_name' in $target_dir...\033[0m"

  mkdir -p "$target_dir/pages"
  mkdir -p "$target_dir/components"
  mkdir -p "$target_dir/composables"
  mkdir -p "$target_dir/services"
  mkdir -p "$target_dir/types"
  mkdir -p "$target_dir/stores"

  # Scaffold module configuration files
  sed "s/{{MODULE_NAME}}/$module_name/g" "$cli_dir/templates/package_json.template" > "$target_dir/package.json"
  cp "$cli_dir/templates/nuxt_config_module.template" "$target_dir/nuxt.config.ts" 2>/dev/null || \
    cp "$cli_dir/templates/nuxt_config.template" "$target_dir/nuxt.config.ts"
  echo "{\"extends\": \"$tsconfig_extends\"}" > "$target_dir/tsconfig.json"

  sed -e "s/{{MODULE_NAME}}/$module_name/g" -e "s/{{CONFIG_KEY}}/$config_key/g" \
    "$cli_dir/templates/index_ts.template" > "$target_dir/index.ts"

  sed "s/{{MODULE_NAME}}/$module_name/g" "$cli_dir/templates/app_vue.template" > "$target_dir/app.vue"

  # Scaffold predefined directories with examples & READMEs
  sed -e "s/{{MODULE_NAME}}/$module_name/g" -e "s/{{CONFIG_KEY}}/$config_key/g" \
    "$cli_dir/templates/module_dirs/pages/index_vue.template" > "$target_dir/pages/index.vue"
  sed "s/{{MODULE_NAME}}/$module_name/g" "$cli_dir/templates/module_dirs/pages/README.md.template" > "$target_dir/pages/README.md"

  sed -e "s/{{MODULE_NAME}}/$module_name/g" -e "s/{{CONFIG_KEY}}/$config_key/g" \
    "$cli_dir/templates/module_dirs/components/ExampleComponent.vue.template" > "$target_dir/components/ExampleComponent.vue"
  sed "s/{{MODULE_NAME}}/$module_name/g" "$cli_dir/templates/module_dirs/components/README.md.template" > "$target_dir/components/README.md"

  sed -e "s/{{MODULE_NAME}}/$module_name/g" -e "s/{{CONFIG_KEY}}/$config_key/g" \
    "$cli_dir/templates/module_dirs/composables/useExample.ts.template" > "$target_dir/composables/useExample.ts"
  sed "s/{{MODULE_NAME}}/$module_name/g" "$cli_dir/templates/module_dirs/composables/README.md.template" > "$target_dir/composables/README.md"

  sed -e "s/{{MODULE_NAME}}/$module_name/g" -e "s/{{CONFIG_KEY}}/$config_key/g" \
    "$cli_dir/templates/module_dirs/services/exampleService.ts.template" > "$target_dir/services/exampleService.ts"
  sed "s/{{MODULE_NAME}}/$module_name/g" "$cli_dir/templates/module_dirs/services/README.md.template" > "$target_dir/services/README.md"

  sed -e "s/{{MODULE_NAME}}/$module_name/g" -e "s/{{CONFIG_KEY}}/$config_key/g" \
    "$cli_dir/templates/module_dirs/types/example.types.ts.template" > "$target_dir/types/example.types.ts"
  sed "s/{{MODULE_NAME}}/$module_name/g" "$cli_dir/templates/module_dirs/types/README.md.template" > "$target_dir/types/README.md"

  sed -e "s/{{MODULE_NAME}}/$module_name/g" -e "s/{{CONFIG_KEY}}/$config_key/g" \
    "$cli_dir/templates/module_dirs/stores/exampleStore.ts.template" > "$target_dir/stores/exampleStore.ts"
  sed "s/{{MODULE_NAME}}/$module_name/g" "$cli_dir/templates/module_dirs/stores/README.md.template" > "$target_dir/stores/README.md"

  # Setup Tailwind config
  setup_tailwind "$target_dir"

  # Setup Git repository & .gitignore
  setup_git "$target_dir" "$cli_dir/templates/gitignore.template"

  # Auto-register module in nuxt.config.ts if inside Nuxt project
  if [ "$is_inside_nuxt" = true ]; then
    register_in_nuxt_config "./modules/$module_name"
  fi

  # Install Node dependencies & prepare Nuxt with progress bar
  ( cd "$target_dir" && run_with_progress "Installing dependencies for '$module_name'" npm install )
  ( cd "$target_dir" && run_with_progress "Generating Nuxt TypeScript declarations (nuxt prepare)" npx -y nuxt prepare )

  echo ""
  echo -e "\033[1;32m[SUCCESS] Autonomous Nuxt module '$module_name' created in $target_dir\033[0m"
  echo -e "\033[0;36m[NEXT STEPS] Test standalone by running:\033[0m"
  echo -e "  \033[1;37mcd $target_dir && npm run dev\033[0m"
  echo ""
}
