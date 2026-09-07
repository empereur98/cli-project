#!/bin/bash

run_with_progress() {
  local msg="$1"
  shift
  local log_file=$(mktemp /tmp/nx_task_XXXXXX.log)
  local pid

  # Execute command directly with preserved arguments
  "$@" > "$log_file" 2>&1 &
  pid=$!

  # Prevent terminal wrapping by truncating the message if it's too long
  local term_width=$(tput cols 2>/dev/null || echo 80)
  # Visual fixed chars: "[PROGRESS] " (11) + "... " (4) + "[" (1) + "]" (1) + " 100%" (5) = 22
  local fixed_chars=22
  local width=20
  local max_msg_len=$(( term_width - width - fixed_chars ))
  
  if [ ${#msg} -gt $max_msg_len ]; then
    if [ $max_msg_len -gt 3 ]; then
      msg="${msg:0:$((max_msg_len - 3))}..."
    else
      msg=""
    fi
  else
    local extra_space=$(( max_msg_len - ${#msg} ))
    width=$(( 20 + extra_space ))
    if [ $width -gt 30 ]; then
      width=30
    fi
  fi
  
  local percent=0
  local step=0

  # Hide cursor during rendering if supported
  tput civis 2>/dev/null || true

  while kill -0 $pid 2>/dev/null; do
    step=$(( step + 1 ))

    local line_count=0
    if [ -f "$log_file" ]; then
      line_count=$(wc -l < "$log_file" 2>/dev/null || echo 0)
    fi

    # Dynamic percentage calculation — progressive even without log output
    if [ $line_count -gt 0 ]; then
      percent=$(( step * 2 ))
    else
      # Logarithmic-style progression: fast at first, slows down over time
      # Ensures the bar never gets stuck at a low value
      if [ $step -le 50 ]; then
        percent=$(( step ))
      elif [ $step -le 150 ]; then
        percent=$(( 50 + (step - 50) / 3 ))
      else
        percent=$(( 83 + (step - 150) / 10 ))
      fi
    fi
    if [ $percent -gt 92 ]; then
      percent=92
    fi

    local filled=$(( (percent * width) / 100 ))
    local empty=$(( width - filled ))
    local bar=""
    if [ $filled -gt 0 ]; then
      bar=$(printf "%0.s█" $(seq 1 $filled))
    fi
    if [ $empty -gt 0 ]; then
      bar="${bar}$(printf "%0.s░" $(seq 1 $empty))"
    fi

    printf "\r\033[K\033[1;34m[PROGRESS]\033[0m %s... \033[1;36m[%s]\033[0m \033[1;33m%3d%%\033[0m" "$msg" "$bar" "$percent"
    sleep 0.4
  done

  wait $pid 2>/dev/null
  local exit_code=$?

  # Restore cursor
  tput cnorm 2>/dev/null || true

  if [ $exit_code -eq 0 ]; then
    percent=100
    local bar=$(printf "%0.s█" $(seq 1 $width))
    printf "\r\033[K\033[1;34m[PROGRESS]\033[0m %s... \033[1;32m[%s] 100%% [SUCCÈS]\033[0m\n" "$msg" "$bar"
    rm -f "$log_file"
    return 0
  else
    printf "\r\033[K\033[1;34m[PROGRESS]\033[0m %s... \033[1;31m[ÉCHEC]\033[0m\n" "$msg"
    echo -e "\033[1;31m[ERROR] La commande a échoué avec le code $exit_code. Détails des erreurs :\033[0m"
    if [ -f "$log_file" ]; then
      echo -e "\033[0;37m----------------------------------------\033[0m"
      tail -n 25 "$log_file"
      echo -e "\033[0;37m----------------------------------------\033[0m"
      rm -f "$log_file"
    fi
    return $exit_code
  fi
}
