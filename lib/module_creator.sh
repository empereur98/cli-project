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

  # Feature-Driven Development rule: must be run inside an existing Nuxt project
  if [ ! -f "./nuxt.config.ts" ] && [ ! -f "./nuxt.config.js" ] && [ ! -f "./nuxt.config.mjs" ]; then
    echo -e "\033[1;31m[ERROR] Feature modules must be created inside an existing Nuxt project.\033[0m"
    echo -e "\033[0;33m[HINT] Navigate to your Nuxt project root (where nuxt.config.ts is located) or create one with:\033[0m"
    echo -e "  ./nx create <project_name>"
    exit 1
  fi

  local target_dir="./modules/$module_name"

  if [ -d "$target_dir" ]; then
    echo -e "\033[1;31m[ERROR] Directory '$target_dir' already exists. Aborting.\033[0m"
    exit 1
  fi

  echo -e "\033[1;34m[INFO] Scaffolding feature module '$module_name' in $target_dir...\033[0m"

  mkdir -p "$target_dir/pages"
  mkdir -p "$target_dir/components"
  mkdir -p "$target_dir/composables"
  mkdir -p "$target_dir/services"
  mkdir -p "$target_dir/types"
  mkdir -p "$target_dir/stores"

  # Nuxt Kit module definition: auto-registers components, composables, stores, and pages
  sed -e "s/{{MODULE_NAME}}/$module_name/g" -e "s/{{CONFIG_KEY}}/$config_key/g" \
    "$cli_dir/templates/index_ts.template" > "$target_dir/index.ts"

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

  # Auto-register module in nuxt.config.ts
  register_in_nuxt_config "./modules/$module_name"

  # Sync into nx.config.json if file exists
  if [ -f "./nx.config.json" ]; then
    if ! grep -q "\"$module_name\"" ./nx.config.json; then
      local tmp=$(mktemp)
      sed "s/\"modules\": \[/\"modules\": [\n    { \"name\": \"$module_name\", \"type\": \"local\", \"path\": \".\/modules\/$module_name\" },/g" ./nx.config.json > "$tmp" 2>/dev/null && mv "$tmp" ./nx.config.json || true
    fi
  fi

  # Refresh Nuxt TypeScript declarations at the project root
  echo -e "\033[1;34m[INFO] Refreshing Nuxt TypeScript declarations (nuxt prepare)...\033[0m"
  npx -y nuxt prepare >/dev/null 2>&1 || true

  echo ""
  echo -e "\033[1;32m[SUCCESS] Feature module '$module_name' created and connected to host project!\033[0m"
  echo -e "\033[0;36m[INFO] Components, composables, stores, and pages are immediately available.\033[0m"
  echo -e "  - Route : http://localhost:3000/$module_name"
  echo -e "  - Path  : ./modules/$module_name"
  echo ""
}

