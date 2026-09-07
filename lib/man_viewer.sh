#!/bin/bash

show_man() {
  local cli_dir="$1"
  local man_file="$cli_dir/man/nx.1"

  if [ -f "$man_file" ]; then
    if command -v man >/dev/null 2>&1; then
      man "$man_file" || nroff -man "$man_file" | ${PAGER:-less}
    elif command -v nroff >/dev/null 2>&1; then
      nroff -man "$man_file" | ${PAGER:-less}
    else
      cat "$man_file"
    fi
  else
    echo -e "\033[1;31m[ERROR] Manual page not found at $man_file\033[0m"
  fi
}
