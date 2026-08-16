#!/usr/bin/env bash

ror_die() {
  printf 'ror: %s\n' "$*" >&2
  exit 1
}

ror_have() {
  command -v "$1" >/dev/null 2>&1
}

ror_repo_root() {
  local src="${BASH_SOURCE[0]}"
  while [ -h "$src" ]; do
    src="$(readlink "$src")"
  done
  cd "$(dirname "$src")/.." >/dev/null 2>&1 && pwd
}

ror_hr() {
  printf '%s\n' '----------------------------------------'
}

ror_yesno() {
  if "$@" >/dev/null 2>&1; then
    printf 'yes'
  else
    printf 'no'
  fi
}
