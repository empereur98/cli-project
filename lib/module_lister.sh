#!/bin/bash

list_modules() {
  local modules_dir="./modules"

  echo -e "\033[1;37mINSTALLED NUXT MODULES\033[0m"
  echo "------------------------------------------------------------------------------------------------------------------------"
  printf "\033[1;36m%-22s %-12s %-45s %-30s\033[0m\n" "NOM DU MODULE" "VERSION" "DÉPÔT DISTANT" "USAGE / RÔLE"
  echo "------------------------------------------------------------------------------------------------------------------------"

  local count=0

  # Helper function to list a single module path
  render_module_row() {
    local dir="$1"
    local mod_name=$(basename "$dir")
    local version=""
    local remote=""
    local role=""

    # 1. Version via git tag or package.json
    if [ -d "$dir/.git" ] || git -C "$dir" rev-parse --git-dir >/dev/null 2>&1; then
      version=$(git -C "$dir" describe --tags --abbrev=0 2>/dev/null || true)
      if [ -z "$version" ]; then
        version=$(git -C "$dir" tag 2>/dev/null | tail -n 1 || true)
      fi
    fi

    if [ -z "$version" ] && [ -f "$dir/package.json" ]; then
      version=$(grep -o '"version": "[^"]*"' "$dir/package.json" 2>/dev/null | cut -d'"' -f4 || true)
      if [ -n "$version" ]; then
        version="v$version"
      fi
    fi

    version=${version:-"v1.0.0"}

    # 2. Remote repository
    if [ -d "$dir/.git" ] || git -C "$dir" rev-parse --git-dir >/dev/null 2>&1; then
      remote=$(git -C "$dir" config --get remote.origin.url 2>/dev/null || true)
    fi

    if [ -z "$remote" ] && [ -f "./nx.config.json" ]; then
      remote=$(grep -A 2 "\"name\": \"$mod_name\"" ./nx.config.json 2>/dev/null | grep '"repository"' | cut -d'"' -f4 || true)
    fi

    remote=${remote:-"Local"}

    # 3. Usage / Role
    if [ -f "$dir/package.json" ]; then
      role=$(grep -o '"description": "[^"]*"' "$dir/package.json" 2>/dev/null | cut -d'"' -f4 || true)
    fi

    if [ -z "$role" ] && [ -f "$dir/README.md" ]; then
      role=$(head -n 5 "$dir/README.md" 2>/dev/null | grep -v '^#' | grep -v '^$' | head -n 1 || true)
    fi

    role=${role:-"Module autonome"}

    # Truncate strings if too long for clean table rendering
    if [ ${#remote} -gt 43 ]; then
      remote="${remote:0:40}..."
    fi
    if [ ${#role} -gt 28 ]; then
      role="${role:0:25}..."
    fi

    printf "%-22s %-12s %-45s %-30s\n" "$mod_name" "$version" "$remote" "$role"
    count=$((count + 1))
  }

  if [ -d "$modules_dir" ]; then
    for dir in "$modules_dir"/*; do
      if [ -d "$dir" ]; then
        render_module_row "$dir"
      fi
    done
  fi

  # Also scan root directory for standalone modules if outside ./modules
  for dir in ./*; do
    if [ -d "$dir" ] && [ "$dir" != "./modules" ] && [ "$dir" != "./nxt-cli" ] && [ "$dir" != "./node_modules" ] && [ -f "$dir/index.ts" ] && [ -f "$dir/package.json" ]; then
      render_module_row "$dir"
    fi
  done

  echo "------------------------------------------------------------------------------------------------------------------------"
  echo -e "Total: \033[1;32m$count\033[0m module(s) installé(s)."
  echo ""
}
