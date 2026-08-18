#!/usr/bin/env bash
set -u

port="${1:-}"
if ! [[ "$port" =~ ^[0-9]+$ ]] || [ "$port" -lt 1 ] || [ "$port" -gt 65535 ]; then
  printf 'Usage: %s <port>\n' "${0##*/}" >&2
  exit 2
fi

printf 'Local listener/process lookup for port %s\n' "$port"
printf 'Host: %s\n' "$(hostname -f 2>/dev/null || hostname 2>/dev/null || printf unknown)"

found=0
if command -v ss >/dev/null 2>&1; then
  printf '\n===== ss =====\n'
  output="$(ss -lntup 2>/dev/null | awk -v p=":$port" 'NR==1 || $5 ~ (p "$")')"
  printf '%s\n' "$output"
  [ "$(printf '%s\n' "$output" | wc -l | tr -d ' ')" -gt 1 ] && found=1
fi

if command -v lsof >/dev/null 2>&1; then
  printf '\n===== lsof TCP =====\n'
  if lsof -nP -iTCP:"$port" -sTCP:LISTEN 2>/dev/null; then
    found=1
  fi
  printf '\n===== lsof UDP =====\n'
  if lsof -nP -iUDP:"$port" 2>/dev/null; then
    found=1
  fi
fi

if [ "$found" -eq 0 ]; then
  printf '\nNo local listener/process was observed for port %s with the available tools.\n' "$port"
fi
