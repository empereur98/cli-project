#!/bin/bash

push_module() {
  local module_name="$1"
  local commit_msg="$2"
  local branch="$3"

  if [ -z "$module_name" ]; then
    echo -e "\033[1;31m[ERROR] Module name is required.\033[0m"
    echo "Usage: nx -p <module_name> [commit_message] [branch]  OR  nx push <module_name> [message]"
    exit 1
  fi

  # Normalize prefix
  local clean_name="$module_name"
  if [[ "$clean_name" =~ ^[A-Za-z0-9_.-]+-module-(.+)$ ]]; then
    clean_name="${BASH_REMATCH[1]}"
  elif [[ "$clean_name" =~ ^easy-trade-(.+)$ ]]; then
    clean_name="${BASH_REMATCH[1]}"
  fi

  local target_dir=""
  if [ -d "./modules/$clean_name" ]; then
    target_dir="./modules/$clean_name"
  elif [ -d "./modules/$module_name" ]; then
    target_dir="./modules/$module_name"
  elif [ -d "./$clean_name" ]; then
    target_dir="./$clean_name"
  elif [ -d "./$module_name" ]; then
    target_dir="./$module_name"
  else
    echo -e "\033[1;31m[ERROR] Module '$module_name' not found in ./modules.\033[0m"
    exit 1
  fi

  if [ ! -d "$target_dir/.git" ]; then
    echo -e "\033[1;31m[ERROR] Module directory '$target_dir' is not a Git repository. Cannot push.\033[0m"
    exit 1
  fi

  local msg="${commit_msg:-feat: update $clean_name module}"

  echo -e "\033[1;34m[INFO] Staging, committing and pushing module '$clean_name' from $target_dir...\033[0m"
  (
    cd "$target_dir" || exit 1
    git add .
    if [ -n "$(git status --porcelain)" ]; then
      git commit -m "$msg"
      echo -e "\033[1;32m[GIT] Committed: '$msg'\033[0m"
    else
      echo -e "\033[1;33m[INFO] Working tree clean. Pushing existing commits...\033[0m"
    fi

    local target_branch="$branch"
    if [ -z "$target_branch" ]; then
      target_branch=$(git branch --show-current 2>/dev/null || echo "main")
    fi

    echo -e "\033[1;34m[INFO] Pushing to remote repository on branch '$target_branch'...\033[0m"
    if git push origin "$target_branch"; then
      echo ""
      echo -e "\033[1;32m[SUCCESS] Module '$clean_name' pushed successfully to remote repository (origin/$target_branch)!\033[0m"
      echo ""
    else
      echo -e "\033[1;31m[ERROR] git push failed for module '$clean_name'. Check git credentials or remote.\033[0m"
      exit 1
    fi
  )
}
