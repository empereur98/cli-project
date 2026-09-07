#!/bin/bash

init_cli() {
  local cli_dir="$1"
  local nx_script_path="$cli_dir/nx"

  if [ ! -f "$nx_script_path" ]; then
    nx_script_path="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/nx"
  fi

  nx_script_path="$(cd "$(dirname "$nx_script_path")" && pwd)/$(basename "$nx_script_path")"

  echo -e "\033[1;34m[INFO] Initializing global 'nx' CLI command across platforms...\033[0m"

  local os_type="$(uname -s 2>/dev/null || echo "Windows")"

  case "$os_type" in
    Linux*|Darwin*)
      chmod +x "$nx_script_path"
      local bin_target="/usr/local/bin"
      local user_bin="$HOME/.local/bin"
      local installed=false

      if [ -w "$bin_target" ]; then
        ln -sf "$nx_script_path" "$bin_target/nx"
        echo -e "\033[1;32m[SUCCESS] Created global symlink at $bin_target/nx\033[0m"
        installed=true
      else
        mkdir -p "$user_bin"
        ln -sf "$nx_script_path" "$user_bin/nx"
        echo -e "\033[1;32m[SUCCESS] Created user executable symlink at $user_bin/nx\033[0m"
        installed=true

        if [[ ":$PATH:" != *":$user_bin:"* ]]; then
          echo -e "\033[1;33m[NOTE] Adding $user_bin to PATH in shell profile...\033[0m"
          for profile in "$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.profile"; do
            if [ -f "$profile" ]; then
              if ! grep -q "$user_bin" "$profile"; then
                echo "export PATH=\"$user_bin:\$PATH\"" >> "$profile"
              fi
            fi
          done
          export PATH="$user_bin:$PATH"
        fi
      fi
      ;;
    CYGWIN*|MINGW*|MSYS*|Windows*)
      local win_bin="$HOME/.local/bin"
      mkdir -p "$win_bin"
      cp "$cli_dir/nx" "$win_bin/nx" 2>/dev/null || true
      cp "$cli_dir/nx.cmd" "$win_bin/nx.cmd" 2>/dev/null || true
      cp "$cli_dir/nx.ps1" "$win_bin/nx.ps1" 2>/dev/null || true
      chmod +x "$win_bin/nx" 2>/dev/null || true

      if command -v powershell.exe >/dev/null 2>&1; then
        powershell.exe -Command "[Environment]::SetEnvironmentVariable('PATH', [Environment]::GetEnvironmentVariable('PATH', 'User') + ';'$win_bin, 'User')" >/dev/null 2>&1 || true
      fi

      echo -e "\033[1;32m[SUCCESS] Configured global 'nx' command for Windows in $win_bin\033[0m"
      ;;
    *)
      echo -e "\033[1;31m[ERROR] Unsupported OS platform: $os_type\033[0m"
      exit 1
      ;;
  esac

  echo ""
  echo -e "\033[1;32m[SUCCESS] 'nx' is now available globally! You can type 'nx' from any directory in your terminal.\033[0m"
}
