#!/bin/bash

unregister_from_nuxt_config() {
  local module_name="$1"
  local config_file="./nuxt.config.ts"

  if [ -f "$config_file" ]; then
    local tmp=$(mktemp)
    sed -e "s|['\"]./modules/$module_name['\"],*||g" \
        -e "s|['\"]~/modules/$module_name['\"],*||g" "$config_file" > "$tmp" 2>/dev/null && mv "$tmp" "$config_file" || rm -f "$tmp"
  fi
}

unregister_from_nx_config() {
  local module_name="$1"
  local config_file="./nx.config.json"

  if [ -f "$config_file" ]; then
    local tmp=$(mktemp)
    sed -e "/\"name\": \"$module_name\"/d" "$config_file" > "$tmp" 2>/dev/null && mv "$tmp" "$config_file" || rm -f "$tmp"
  fi
}

remove_module() {
  local module_name="$1"
  local cli_dir="$2"

  if [ -z "$module_name" ]; then
    echo -e "\033[1;31m[ERROR] Module or model name is required for deletion (-d).\033[0m"
    echo "Usage: nx -m <module_name> -d  OR  nx -d <module_name>"
    exit 1
  fi

  local clean_name="${module_name#easy-trade-module-}"
  clean_name="${clean_name#easy-trade-}"
  local target_dir=""
  if [ -d "./modules/$clean_name" ]; then
    target_dir="./modules/$clean_name"
  elif [ -d "./modules/$module_name" ]; then
    target_dir="./modules/$module_name"
  elif [ -d "./modules/easy-trade-module-$clean_name" ]; then
    target_dir="./modules/easy-trade-module-$clean_name"
  elif [ -d "./$clean_name" ]; then
    target_dir="./$clean_name"
  elif [ -d "./$module_name" ]; then
    target_dir="./$module_name"
  elif [ -d "./easy-trade-module-$clean_name" ]; then
    target_dir="./easy-trade-module-$clean_name"
  elif [ -d "../modules/$clean_name" ]; then
    target_dir="../modules/$clean_name"
  elif [ -d "../modules/$module_name" ]; then
    target_dir="../modules/$module_name"
  elif [ -d "../modules/easy-trade-module-$clean_name" ]; then
    target_dir="../modules/easy-trade-module-$clean_name"
  else
    echo -e "\033[1;31m[ERROR] Module or model '$module_name' not found in modules directory.\033[0m"
    exit 1
  fi

  echo -e "\033[1;33m[INFO] Removing module '$clean_name' from project...\033[0m"

  # Unregister from nuxt.config.ts & nx.config.json
  unregister_from_nuxt_config "$module_name"
  unregister_from_nuxt_config "$clean_name"
  unregister_from_nx_config "$module_name"
  unregister_from_nx_config "$clean_name"

  # Delete physical directory
  rm -rf "$target_dir"
  echo -e "\033[1;32m[SUCCESS] Deleted directory $target_dir\033[0m"

  # Refresh Nuxt types if inside a Nuxt project
  if [ -f "./nuxt.config.ts" ] || [ -f "./nuxt.config.js" ]; then
    echo -e "\033[1;34m[INFO] Refreshing Nuxt declarations...\033[0m"
    npx nuxt prepare >/dev/null 2>&1 || true
  fi

  echo ""
  echo -e "\033[1;32m[SUCCESS] Module '$module_name' removed successfully from project.\033[0m"
  echo ""
}
