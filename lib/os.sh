#!/usr/bin/env bash

ror_detect_os() {
  ROR_OS="unknown"
  ROR_OS_FAMILY="unknown"
  ROR_ARCH="$(uname -m 2>/dev/null || printf unknown)"
  ROR_WSL="no"

  case "$(uname -s 2>/dev/null)" in
    Linux)
      if grep -qi microsoft /proc/version 2>/dev/null; then
        ROR_WSL="yes"
      fi
      if [ -r /etc/os-release ]; then
        . /etc/os-release
        ROR_OS="${ID:-linux}"
        case "${ID_LIKE:-} ${ID:-}" in
          *rhel*|*fedora*|*centos*|*rocky*|*almalinux*|*ol*) ROR_OS_FAMILY="rhel" ;;
          *debian*|*ubuntu*) ROR_OS_FAMILY="debian" ;;
          *) ROR_OS_FAMILY="linux" ;;
        esac
      else
        ROR_OS="linux"
        ROR_OS_FAMILY="linux"
      fi
      ;;
    Darwin)
      ROR_OS="macos"
      ROR_OS_FAMILY="darwin"
      ;;
    MINGW*|MSYS*|CYGWIN*)
      ROR_OS="windows"
      ROR_OS_FAMILY="windows"
      ;;
  esac

  export ROR_OS ROR_OS_FAMILY ROR_ARCH ROR_WSL
}
