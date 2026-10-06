#!/bin/bash

create_module() {
  local module_name="$1"
  local cli_dir="$2"

  if [ -z "$module_name" ]; then
    echo -e "\033[1;31m[ERROR] Module name is required.\033[0m"
    echo "Usage: ./nx -m <module_name>"
    exit 1
  fi

  # Normalize module name
  module_name="${module_name#easy-trade-module-}"
  module_name="${module_name#easy-trade-}"
  local config_key=$(echo "$module_name" | sed 's/-/_/g')

  local is_inside_nuxt=false
  if [ -f "./nuxt.config.ts" ] || [ -f "./nuxt.config.js" ] || [ -f "./nuxt.config.mjs" ]; then
    is_inside_nuxt=true
  fi

  local target_dir="./$module_name"
  if [ "$is_inside_nuxt" = true ]; then
    mkdir -p ./modules
    target_dir="./modules/$module_name"
  fi

  if [ -d "$target_dir" ]; then
    echo -e "\033[1;31m[ERROR] Directory '$target_dir' already exists. Aborting.\033[0m"
    exit 1
  fi

  echo -e "\033[1;34m[INFO] Scaffolding complete module '$module_name' in $target_dir...\033[0m"

  mkdir -p "$target_dir/pages"
  mkdir -p "$target_dir/components"
  mkdir -p "$target_dir/composables"
  mkdir -p "$target_dir/services"
  mkdir -p "$target_dir/types"
  mkdir -p "$target_dir/stores"

  # 1. Runtime Nuxt Kit definition
  sed -e "s/{{MODULE_NAME}}/$module_name/g" -e "s/{{CONFIG_KEY}}/$config_key/g" \
    "$cli_dir/templates/index_ts.template" > "$target_dir/index.ts"

  # 2. Module manifest
  if [ -f "$cli_dir/templates/module_json.template" ]; then
    sed -e "s/{{MODULE_NAME}}/$module_name/g" -e "s/{{PASCAL_NAME}}/$module_name/g" \
      "$cli_dir/templates/module_json.template" > "$target_dir/module.json"
  fi

  # 3. Module subdirs templates & documentation
  sed -e "s/{{MODULE_NAME}}/$module_name/g" -e "s/{{CONFIG_KEY}}/$config_key/g" \
    "$cli_dir/templates/module_dirs/pages/index_vue.template" > "$target_dir/pages/index.vue"
  sed "s/{{MODULE_NAME}}/$module_name/g" "$cli_dir/templates/module_dirs/pages/README.md.template" > "$target_dir/pages/README.md"

  local pascal_name=$(echo "$module_name" | awk -F'-' '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) substr($i,2)} 1' OFS='')
  local camel_name="$(tr '[:upper:]' '[:lower:]' <<< ${pascal_name:0:1})${pascal_name:1}"

  sed -e "s/{{MODULE_NAME}}/$module_name/g" -e "s/{{CONFIG_KEY}}/$config_key/g" \
    "$cli_dir/templates/module_dirs/components/ExampleComponent.vue.template" > "$target_dir/components/${pascal_name}Component.vue"
  sed "s/{{MODULE_NAME}}/$module_name/g" "$cli_dir/templates/module_dirs/components/README.md.template" > "$target_dir/components/README.md"

  sed -e "s/{{MODULE_NAME}}/$module_name/g" -e "s/{{CONFIG_KEY}}/$config_key/g" -e "s/{{PASCAL_NAME}}/$pascal_name/g" \
    "$cli_dir/templates/module_dirs/composables/useExample.ts.template" > "$target_dir/composables/use${pascal_name}.ts"
  sed "s/{{MODULE_NAME}}/$module_name/g" "$cli_dir/templates/module_dirs/composables/README.md.template" > "$target_dir/composables/README.md"

  sed -e "s/{{MODULE_NAME}}/$module_name/g" -e "s/{{CONFIG_KEY}}/$config_key/g" -e "s/{{PASCAL_NAME}}/$pascal_name/g" \
    "$cli_dir/templates/module_dirs/services/exampleService.ts.template" > "$target_dir/services/${camel_name}Service.ts"
  sed "s/{{MODULE_NAME}}/$module_name/g" "$cli_dir/templates/module_dirs/services/README.md.template" > "$target_dir/services/README.md"

  sed -e "s/{{MODULE_NAME}}/$module_name/g" -e "s/{{CONFIG_KEY}}/$config_key/g" -e "s/{{PASCAL_NAME}}/$pascal_name/g" \
    "$cli_dir/templates/module_dirs/types/example.types.ts.template" > "$target_dir/types/${camel_name}.types.ts"
  sed "s/{{MODULE_NAME}}/$module_name/g" "$cli_dir/templates/module_dirs/types/README.md.template" > "$target_dir/types/README.md"

  sed -e "s/{{MODULE_NAME}}/$module_name/g" -e "s/{{CONFIG_KEY}}/$config_key/g" -e "s/{{PASCAL_NAME}}/$pascal_name/g" \
    "$cli_dir/templates/module_dirs/stores/exampleStore.ts.template" > "$target_dir/stores/${camel_name}Store.ts"
  sed "s/{{MODULE_NAME}}/$module_name/g" "$cli_dir/templates/module_dirs/stores/README.md.template" > "$target_dir/stores/README.md"

  # 4. Standalone config files
  sed -e "s/{{MODULE_NAME}}/$module_name/g" -e "s/{{CONFIG_KEY}}/$config_key/g" \
    "$cli_dir/templates/standalone/package_json.template" > "$target_dir/package.json"
  sed "s/{{MODULE_NAME}}/$module_name/g" "$cli_dir/templates/standalone/README.md.template" > "$target_dir/README.md"
  cp "$cli_dir/templates/gitignore.template" "$target_dir/.gitignore"
  sed "s/{{MODULE_NAME}}/$module_name/g" "$cli_dir/templates/standalone/tsconfig_json.template" > "$target_dir/tsconfig.json"

  # 5. Host project registration
  if [ "$is_inside_nuxt" = true ]; then
    register_in_nuxt_config "./modules/$module_name"
    if [ -f "./nx.config.json" ]; then
      if ! grep -q "\"$module_name\"" ./nx.config.json; then
        local tmp=$(mktemp)
        sed "s/\"modules\": \[/\"modules\": [\n    { \"name\": \"$module_name\", \"type\": \"autonomous\", \"path\": \".\/modules\/$module_name\" },/g" ./nx.config.json > "$tmp" 2>/dev/null && mv "$tmp" ./nx.config.json || true
      fi
    fi
  fi

  # 6. Refresh Nuxt TypeScript declarations
  echo -e "\033[1;34m[INFO] Refreshing Nuxt TypeScript declarations (nuxt prepare)...\033[0m"
  npx -y nuxt prepare >/dev/null 2>&1 || true

  echo ""
  echo -e "\033[1;32m[SUCCESS] Module '$module_name' created successfully in $target_dir!\033[0m"
  echo -e "  - Route locale  : http://localhost:3000/$module_name"
  echo -e "  - Dossier local : ./modules/$module_name"
  echo ""
}
