#!/usr/bin/env bash

workflow_section() {
  printf '\n%s\n' "$1"
  printf '%s\n' '----------------------------------------'
}

workflow_item() {
  local state="$1" label="$2" detail="${3:-}"
  printf '  [%-5s] %-24s %s\n' "$state" "$label" "$detail"
}

workflow_have() { command -v "$1" >/dev/null 2>&1; }

workflow_is_root() {
  [ "$(id -u 2>/dev/null || printf 1)" -eq 0 ]
}

workflow_can_elevate() {
  workflow_is_root || workflow_have sudo
}

workflow_run_root() {
  if workflow_is_root; then
    "$@"
  elif workflow_have sudo; then
    sudo "$@"
  else
    printf 'Root privileges are required for: %s\n' "$*" >&2
    return 126
  fi
}

workflow_append_root() {
  local line="$1" path="$2"
  if workflow_is_root; then
    printf '%s\n' "$line" >> "$path"
  elif workflow_have sudo; then
    printf '%s\n' "$line" | sudo tee -a "$path" >/dev/null
  else
    printf 'Root privileges are required to append %s\n' "$path" >&2
    return 126
  fi
}

workflow_no_whitespace() {
  case "$1" in
    *[[:space:]]*) return 1 ;;
    *) return 0 ;;
  esac
}

workflow_plan_only_banner() {
  printf 'Changes: NONE (plan/preflight only).\n'
  printf 'Add --apply only after reviewing the preflight and plan.\n'
}
