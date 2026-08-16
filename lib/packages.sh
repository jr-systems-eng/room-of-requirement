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

ror_privilege_prefix() {
  if [ "$(id -u 2>/dev/null || printf 1)" -eq 0 ]; then
    printf '\n'
  elif command -v sudo >/dev/null 2>&1; then
    printf 'sudo\n'
  else
    return 1
  fi
}

ror_install_command() {
  local manager="$1" prefix
  shift
  [ "$#" -gt 0 ] || return 0
  prefix="$(ror_privilege_prefix 2>/dev/null || true)"

  case "$manager" in
    dnf)
      [ -n "$prefix" ] && printf '%s ' "$prefix"
      printf 'dnf install -y'; printf ' %q' "$@"; printf '\n'
      ;;
    apt)
      [ -n "$prefix" ] && printf '%s ' "$prefix"
      printf 'apt-get update && '
      [ -n "$prefix" ] && printf '%s ' "$prefix"
      printf 'apt-get install -y'; printf ' %q' "$@"; printf '\n'
      ;;
    zypper)
      [ -n "$prefix" ] && printf '%s ' "$prefix"
      printf 'zypper install -y'; printf ' %q' "$@"; printf '\n'
      ;;
    pacman)
      [ -n "$prefix" ] && printf '%s ' "$prefix"
      printf 'pacman -S --needed'; printf ' %q' "$@"; printf '\n'
      ;;
    brew) printf 'brew install'; printf ' %q' "$@"; printf '\n' ;;
    winget) printf 'winget install'; printf ' %q' "$@"; printf '\n' ;;
    *) printf '# No supported package manager detected\n' ;;
  esac
}

ror_install_packages() {
  local manager="$1" prefix
  shift
  [ "$#" -gt 0 ] || return 0
  prefix="$(ror_privilege_prefix 2>/dev/null || true)"

  case "$manager" in
    dnf)
      if [ -n "$prefix" ]; then sudo dnf install -y "$@"; else dnf install -y "$@"; fi
      ;;
    apt)
      if [ -n "$prefix" ]; then
        sudo apt-get update && sudo apt-get install -y "$@"
      else
        apt-get update && apt-get install -y "$@"
      fi
      ;;
    zypper)
      if [ -n "$prefix" ]; then sudo zypper install -y "$@"; else zypper install -y "$@"; fi
      ;;
    pacman)
      if [ -n "$prefix" ]; then sudo pacman -S --needed "$@"; else pacman -S --needed "$@"; fi
      ;;
    brew) brew install "$@" ;;
    winget)
      local package
      for package in "$@"; do winget install "$package" || return $?; done
      ;;
    *) return 2 ;;
  esac
}

# `bin/ror` originally used sudo directly for package installation. On minimal
# servers root may be the active user and sudo may not be installed. Provide a
# process-local compatibility function only in that exact case; it simply runs
# the requested command directly and is not exported to child shells.
if [ "$(id -u 2>/dev/null || printf 1)" -eq 0 ] && ! command -v sudo >/dev/null 2>&1; then
  sudo() { "$@"; }
fi
