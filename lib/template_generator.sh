#!/bin/bash

generate_module() {
  local module_name="$1"
  local cli_dir="$2"
  local target_dir="./$module_name"
  local config_key=$(echo "$module_name" | sed 's/-/_/g')

  if [ -d "$target_dir" ]; then
    echo -e "\033[1;31m[ERROR] Directory '$target_dir' already exists. Aborting.\033[0m"
    exit 1
  fi

  mkdir -p "$target_dir/pages"
  mkdir -p "$target_dir/components"
  mkdir -p "$target_dir/composables"
  mkdir -p "$target_dir/services"
  mkdir -p "$target_dir/types"
  mkdir -p "$target_dir/stores"

  # Process and copy templates
  sed "s/{{MODULE_NAME}}/$module_name/g" "$cli_dir/templates/package_json.template" > "$target_dir/package.json"
  cp "$cli_dir/templates/nuxt_config.template" "$target_dir/nuxt.config.ts"
  echo '{"extends": "./.nuxt/tsconfig.json"}' > "$target_dir/tsconfig.json"

  sed -e "s/{{MODULE_NAME}}/$module_name/g" -e "s/{{CONFIG_KEY}}/$config_key/g" \
    "$cli_dir/templates/index_ts.template" > "$target_dir/index.ts"

  sed "s/{{MODULE_NAME}}/$module_name/g" "$cli_dir/templates/app_vue.template" > "$target_dir/app.vue"

  # Scaffold predefined directories with examples & READMEs
  sed -e "s/{{MODULE_NAME}}/$module_name/g" -e "s/{{CONFIG_KEY}}/$config_key/g" \
    "$cli_dir/templates/module_dirs/pages/ExamplePage.vue.template" > "$target_dir/pages/ExamplePage.vue"
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

  # Setup Tailwind CSS config
  setup_tailwind "$target_dir"

  # Setup Git repository & .gitignore
  setup_git "$target_dir" "$cli_dir/templates/gitignore.template"

  # Install Node dependencies
  echo -e "\033[1;32m[INFO] Installing dependencies for '$module_name'...\033[0m"
  (cd "$target_dir" && npm install)

  echo ""
  echo -e "\033[1;32m[SUCCESS] Autonomous Nuxt module '$module_name' created successfully.\033[0m"
  echo -e "\033[0;36m[NEXT STEPS] Run the following command to start local development:\033[0m"
  echo -e "  \033[1;37mcd $target_dir && npm run dev\033[0m"
  echo ""
}
