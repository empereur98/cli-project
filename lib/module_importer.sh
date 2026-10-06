#!/bin/bash

register_in_nuxt_config() {
  local module_path="$1"
  local config_file="./nuxt.config.ts"
  [ ! -f "$config_file" ] && config_file="./nuxt.config.js"
  [ ! -f "$config_file" ] && config_file="./nuxt.config.mjs"

  if [ -f "$config_file" ]; then
    if grep -q "getDiscoveredModules" "$config_file"; then
      return 0
    fi
    if ! grep -q "$module_path" "$config_file"; then
      if grep -q "modules: \[" "$config_file"; then
        sed -i "s|modules: \[|modules: [\n    '$module_path',|g" "$config_file" 2>/dev/null || \
        sed -i "" "s|modules: \[|modules: [\n    '$module_path',|g" "$config_file" 2>/dev/null || true
      elif grep -q "defineNuxtConfig({" "$config_file"; then
        sed -i "s|defineNuxtConfig({|defineNuxtConfig({\n  modules: ['$module_path'],|g" "$config_file" 2>/dev/null || \
        sed -i "" "s|defineNuxtConfig({|defineNuxtConfig({\n  modules: ['$module_path'],|g" "$config_file" 2>/dev/null || true
      fi
    fi
  fi
}

import_module() {
  local repo_url="$1"
  local target_name="$2"
  local cli_dir="$3"
  local branch="${4:-main}"

  if [ -z "$repo_url" ]; then
    if [ -f "./nx.config.json" ]; then
      echo -e "\033[1;34m[INFO] Syncing all modules defined in nx.config.json...\033[0m"
      local repos=$(grep -o '"repository": "[^"]*"' ./nx.config.json | cut -d'"' -f4)
      for url in $repos; do
        import_module "$url" "" "$cli_dir"
      done
      return 0
    else
      echo -e "\033[1;31m[ERROR] No URL specified and no nx.config.json found.\033[0m"
      exit 1
    fi
  fi

  # Normalize shorthand repo format (e.g., user/repo -> https://github.com/user/repo.git or module-name)
  if [[ ! "$repo_url" =~ ^https?:// ]] && [[ ! "$repo_url" =~ ^git@ ]] && [[ ! "$repo_url" =~ ^ssh:// ]]; then
    if [[ "$repo_url" =~ ^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$ ]]; then
      repo_url="https://github.com/$repo_url.git"
    elif [[ "$repo_url" =~ ^[A-Za-z0-9_.-]+$ ]]; then
      default_owner="empereur98"
      origin_url=$(git config --get remote.origin.url 2>/dev/null || true)
      if [[ "$origin_url" =~ github\.com[:/]([^/]+)/ ]]; then
        default_owner="${BASH_REMATCH[1]}"
      fi
      repo_name="$repo_url"
      if [[ ! "$repo_name" =~ ^easy-trade-module- ]]; then
        repo_name="easy-trade-module-$repo_name"
      fi
      repo_url="https://github.com/$default_owner/$repo_name.git"
    fi
  fi

  # Check existence of remote repository BEFORE creating anything locally
  echo -e "\033[1;34m[INFO] Checking existence of remote repository '$repo_url'...\033[0m"
  if ! check_repo_exists "$repo_url"; then
    echo -e "\033[1;31m[ERROR] Remote repository '$repo_url' does not exist or is inaccessible. Aborting import.\033[0m"
    return 1 2>/dev/null || exit 1
  fi

  clean_module_name() {
    local raw="$1"
    raw=$(basename "$raw" .git)
    # 1. Matches <anything>-module-<name>
    if [[ "$raw" =~ ^[A-Za-z0-9_.-]+-module-(.+)$ ]]; then
      echo "${BASH_REMATCH[1]}"
      return 0
    fi
    # 2. Matches easy-trade-<name>
    if [[ "$raw" =~ ^easy-trade-(.+)$ ]]; then
      echo "${BASH_REMATCH[1]}"
      return 0
    fi
    # 3. Matches <project_name>-<name>
    local proj=""
    if [ -f "./nx.config.json" ]; then
      proj=$(grep -o '"name": "[^"]*"' ./nx.config.json | head -1 | cut -d'"' -f4)
    fi
    if [ -z "$proj" ]; then
      proj=$(basename "$(pwd)")
    fi
    if [ -n "$proj" ]; then
      local base_prefix="${proj%-dashboard*}"
      if [[ "$raw" =~ ^$proj-(.+)$ ]]; then
        echo "${BASH_REMATCH[1]}"
        return 0
      fi
      if [ -n "$base_prefix" ] && [[ "$raw" =~ ^$base_prefix-(.+)$ ]]; then
        echo "${BASH_REMATCH[1]}"
        return 0
      fi
    fi
    echo "$raw"
  }

  if [ -z "$target_name" ]; then
    target_name=$(clean_module_name "$repo_url")
  else
    target_name=$(clean_module_name "$target_name")
  fi

  local target_dir="./modules/$target_name"

  if [ -d "$target_dir" ]; then
    echo -e "\033[1;33m[WARN] Module '$target_name' already exists at $target_dir. Updating...\033[0m"
    (cd "$target_dir" && git pull origin "$branch" || echo -e "\033[1;31m[ERROR] Failed to update module '$target_name'. Check git status or conflicts.\033[0m")
  else
    echo -e "\033[1;34m[INFO] Cloning remote module '$target_name' from $repo_url...\033[0m"
    mkdir -p ./modules
    if ! git clone --depth 1 --single-branch --branch "$branch" "$repo_url" "$target_dir" 2>/dev/null; then
      if ! git clone --depth 1 "$repo_url" "$target_dir" 2>/dev/null; then
        echo -e "\033[1;31m[ERROR] Failed to clone remote module '$target_name' from $repo_url. Aborting.\033[0m"
        rm -rf "$target_dir"
        return 1 2>/dev/null || exit 1
      fi
    fi
  fi

  # Ensure imported module tsconfig.json extends the parent project's .nuxt folder
  if [ -f "$target_dir/tsconfig.json" ]; then
    echo '{"extends": "../../.nuxt/tsconfig.json"}' > "$target_dir/tsconfig.json"
  fi

  register_in_nuxt_config "./modules/$target_name"

  # Sync into nx.config.json if file exists
  if [ -f "./nx.config.json" ]; then
    if ! grep -q "\"$target_name\"" ./nx.config.json; then
      local tmp=$(mktemp)
      sed "s/\"modules\": \[/\"modules\": [\n    { \"name\": \"$target_name\", \"repository\": \"$repo_url\", \"branch\": \"$branch\" },/g" ./nx.config.json > "$tmp" 2>/dev/null && mv "$tmp" ./nx.config.json || true
    fi
  fi

  echo -e "\033[1;32m[INFO] Installing dependencies & preparing Nuxt types...\033[0m"
  npm install >/dev/null 2>&1 || true
  npx nuxt prepare >/dev/null 2>&1 || true

  echo -e "\033[1;32m[SUCCESS] Module '$target_name' imported successfully.\033[0m"
}
