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

ror_profile_names() {
  printf '%s\n' minimal troubleshooting networking linux-admin development ansible containers kubernetes cloud
}

ror_profile_description() {
  case "$1" in
    minimal) printf 'small portable baseline: Git, curl, jq\n' ;;
    troubleshooting) printf 'general incident and host troubleshooting tools\n' ;;
    networking) printf 'DNS, TCP, TLS, packet, and path troubleshooting tools\n' ;;
    linux-admin) printf 'everyday Linux administration workstation/jumpbox toolkit\n' ;;
    development) printf 'Git, Python, jq, curl, and terminal development basics\n' ;;
    ansible) printf 'Ansible control-node basics using distro packages\n' ;;
    containers) printf 'container CLI prerequisites plus distro Podman where available\n' ;;
    kubernetes) printf 'Kubernetes prerequisites; kubectl/helm remain explicit external tools\n' ;;
    cloud) printf 'cloud CLI prerequisites; provider/vSphere CLIs remain explicit external tools\n' ;;
    *) printf 'single tool/package request\n' ;;
  esac
}

ror_profile_tools() {
  case "${1:-troubleshooting}" in
    minimal)
      printf '%s\n' git curl jq
      ;;
    troubleshooting)
      printf '%s\n' curl wget jq lsof strace tcpdump dig nc openssl git tmux
      ;;
    networking)
      printf '%s\n' curl jq tcpdump dig nc openssl traceroute
      ;;
    linux-admin)
      printf '%s\n' vim git curl wget jq tmux rsync tree unzip lsof strace tcpdump dig nc openssl traceroute sysstat
      ;;
    development)
      printf '%s\n' git curl jq python3 pip3 tmux
      ;;
    ansible)
      printf '%s\n' git python3 pip3 ansible
      ;;
    containers)
      printf '%s\n' curl jq openssl podman
      ;;
    kubernetes)
      printf '%s\n' curl jq openssl
      ;;
    cloud)
      printf '%s\n' curl jq python3
      ;;
    *)
      printf '%s\n' "$1"
      ;;
  esac
}

ror_profile_external_tools() {
  case "$1" in
    containers) printf '%s\n' docker ;;
    kubernetes) printf '%s\n' kubectl helm ;;
    cloud) printf '%s\n' gcloud govc ;;
  esac
}

ror_profile_is_named() {
  local wanted="$1" profile
  while IFS= read -r profile; do
    [ "$profile" = "$wanted" ] && return 0
  done < <(ror_profile_names)
  return 1
}

ror_package_name() {
  local manager="$1" tool="$2"
  case "$manager:$tool" in
    dnf:dig) printf 'bind-utils\n' ;;
    dnf:nc) printf 'nmap-ncat\n' ;;
    dnf:vim) printf 'vim-enhanced\n' ;;
    dnf:pip3) printf 'python3-pip\n' ;;
    dnf:ansible) printf 'ansible-core\n' ;;

    apt:dig) printf 'dnsutils\n' ;;
    apt:nc) printf 'netcat-openbsd\n' ;;
    apt:pip3) printf 'python3-pip\n' ;;

    pacman:dig) printf 'bind\n' ;;
    pacman:nc) printf 'openbsd-netcat\n' ;;
    pacman:pip3) printf 'python-pip\n' ;;

    brew:python3|brew:pip3) printf 'python\n' ;;

    *) printf '%s\n' "$tool" ;;
  esac
}

ror_missing_profile_packages() {
  local profile="$1" manager tool package
  manager="$(ror_package_manager)"
  while IFS= read -r tool; do
    [ -n "$tool" ] || continue
    command -v "$tool" >/dev/null 2>&1 && continue
    package="$(ror_package_name "$manager" "$tool")"
    printf '%s\n' "$package"
  done < <(ror_profile_tools "$profile") | sort -u
}

# Backward-compatible name used by earlier ror releases.
ror_missing_bundle_packages() {
  ror_missing_profile_packages "$@"
}

ror_missing_external_tools() {
  local profile="$1" tool
  while IFS= read -r tool; do
    [ -n "$tool" ] || continue
    command -v "$tool" >/dev/null 2>&1 || printf '%s\n' "$tool"
  done < <(ror_profile_external_tools "$profile")
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
