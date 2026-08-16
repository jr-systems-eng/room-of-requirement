#!/usr/bin/env bash

ror_package_manager() {
  if command -v dnf >/dev/null 2>&1; then printf 'dnf\n'
  elif command -v apt-get >/dev/null 2>&1; then printf 'apt\n'
  elif command -v zypper >/dev/null 2>&1; then printf 'zypper\n'
  elif command -v pacman >/dev/null 2>&1; then printf 'pacman\n'
  elif command -v brew >/dev/null 2>&1; then printf 'brew\n'
  elif command -v winget >/dev/null 2>&1; then printf 'winget\n'
  else printf 'unknown\n'
  fi
}

ror_bundle_tools() {
  case "${1:-troubleshooting}" in
    troubleshooting)
      printf '%s\n' curl wget jq lsof strace tcpdump dig nc openssl git tmux
      ;;
    networking)
      printf '%s\n' curl jq tcpdump dig nc openssl traceroute
      ;;
    development)
      printf '%s\n' git curl jq python3 tmux
      ;;
    *)
      printf '%s\n' "$1"
      ;;
  esac
}

ror_package_name() {
  local manager="$1" tool="$2"
  case "$manager:$tool" in
    dnf:dig) printf 'bind-utils\n' ;;
    dnf:nc) printf 'nmap-ncat\n' ;;
    apt:dig) printf 'dnsutils\n' ;;
    apt:nc) printf 'netcat-openbsd\n' ;;
    pacman:dig) printf 'bind\n' ;;
    pacman:nc) printf 'openbsd-netcat\n' ;;
    *) printf '%s\n' "$tool" ;;
  esac
}

ror_missing_bundle_packages() {
  local bundle="$1" manager tool package
  manager="$(ror_package_manager)"
  while IFS= read -r tool; do
    [ -n "$tool" ] || continue
    command -v "$tool" >/dev/null 2>&1 && continue
    package="$(ror_package_name "$manager" "$tool")"
    printf '%s\n' "$package"
  done < <(ror_bundle_tools "$bundle")
}

ror_install_command() {
  local manager="$1"; shift
  [ "$#" -gt 0 ] || return 0
  case "$manager" in
    dnf) printf 'sudo dnf install -y'; printf ' %q' "$@"; printf '\n' ;;
    apt) printf 'sudo apt-get update && sudo apt-get install -y'; printf ' %q' "$@"; printf '\n' ;;
    zypper) printf 'sudo zypper install -y'; printf ' %q' "$@"; printf '\n' ;;
    pacman) printf 'sudo pacman -S --needed'; printf ' %q' "$@"; printf '\n' ;;
    brew) printf 'brew install'; printf ' %q' "$@"; printf '\n' ;;
    winget) printf 'winget install'; printf ' %q' "$@"; printf '\n' ;;
    *) printf '# No supported package manager detected\n' ;;
  esac
}
