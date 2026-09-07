#!/bin/bash

setup_git() {
  local target_dir="$1"
  local gitignore_template="$2"

  # 1. Copy gitignore template
  cp "$gitignore_template" "$target_dir/.gitignore"

  # Check if TTY is available for interactive prompt
  if [ ! -t 0 ]; then
    echo "[GIT] Non-interactive mode detected. Skipping git initialization."
    return 0
  fi

  echo ""
  read -p "Do you want to initialize Git in this module? [y/N]: " use_git
  case "$use_git" in
    [yY][eE][sS]|[yY])
      read -p "Enter main branch name [default: main]: " branch_name
      branch_name=${branch_name:-"main"}

      read -p "Enter GitHub remote repository URL (optional): " remote_url

      echo "[GIT] Initializing repository on branch '$branch_name'..."
      (
        cd "$target_dir"
        git init -b "$branch_name" > /dev/null 2>&1 || git init > /dev/null 2>&1
        if [ -n "$remote_url" ]; then
          git remote add origin "$remote_url" > /dev/null 2>&1 || true
          echo "[GIT] Remote origin set to $remote_url"
        fi
      )
      ;;
    *)
      echo "[GIT] Git initialization skipped."
      ;;
  esac
}

check_repo_exists() {
  local repo_url="$1"

  if [ -z "$repo_url" ]; then
    return 1
  fi

  if git ls-remote "$repo_url" HEAD >/dev/null 2>&1 || git ls-remote "$repo_url" >/dev/null 2>&1; then
    return 0
  else
    return 1
  fi
}
