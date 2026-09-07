#!/bin/bash

update_module() {
  local module_name="$1"
  local modules_dir="./modules"

  if [ -n "$module_name" ]; then
    local target_dir="$modules_dir/$module_name"
    if [ ! -d "$target_dir" ]; then
      echo -e "\033[1;31m[ERROR] Module '$module_name' not found in $modules_dir.\033[0m"
      exit 1
    fi
    echo -e "\033[1;34m[INFO] Updating module '$module_name'...\033[0m"
    (
      cd "$target_dir" || exit 1
      local branch=$(git branch --show-current)
      if [ -n "$branch" ]; then
        git pull origin "$branch" || echo -e "\033[1;31m[ERROR] Pull failed for '$module_name'. Check git status or conflicts.\033[0m"
      else
        git pull || echo -e "\033[1;31m[ERROR] Pull failed for '$module_name'. Check git status or conflicts.\033[0m"
      fi
    )
    if [ -f "$target_dir/tsconfig.json" ]; then
      echo '{"extends": "../../.nuxt/tsconfig.json"}' > "$target_dir/tsconfig.json"
    fi
  else
    echo -e "\033[1;34m[INFO] Updating all modules in $modules_dir...\033[0m"
    if [ -d "$modules_dir" ]; then
      for dir in "$modules_dir"/*; do
        if [ -d "$dir" ] && [ -d "$dir/.git" ]; then
          local mod=$(basename "$dir")
          echo -e "\033[1;36m[UPDATE] Pulling latest changes for '$mod'...\033[0m"
          (
            cd "$dir" || exit 1
            local branch=$(git branch --show-current)
            if [ -n "$branch" ]; then
              git pull origin "$branch" || echo -e "\033[1;31m[ERROR] Pull failed for '$mod'.\033[0m"
            else
              git pull || echo -e "\033[1;31m[ERROR] Pull failed for '$mod'.\033[0m"
            fi
          )
          if [ -f "$dir/tsconfig.json" ]; then
            echo '{"extends": "../../.nuxt/tsconfig.json"}' > "$dir/tsconfig.json"
          fi
        fi
      done
    fi
  fi

  echo -e "\033[1;32m[INFO] Refreshing npm dependencies & Nuxt types...\033[0m"
  npm install >/dev/null 2>&1 || true
  npx nuxt prepare >/dev/null 2>&1 || true

  echo -e "\033[1;32m[SUCCESS] Update process completed.\033[0m"
}
