#!/usr/bin/env bash
set -u

section() { printf '\n===== %s =====\n' "$1"; }
run() { printf '\n$ %s\n' "$*"; "$@" 2>&1 || true; }

section INTERFACES
run sh -c 'command -v ip >/dev/null && ip -brief link'
run sh -c 'command -v ip >/dev/null && ip -brief addr'

section ROUTING
run sh -c 'command -v ip >/dev/null && ip route'
run sh -c 'command -v ip >/dev/null && ip rule'

section NEIGHBORS
run sh -c 'command -v ip >/dev/null && ip neigh'

section LISTENERS
run sh -c 'command -v ss >/dev/null && ss -lntup'

section DNS
if command -v resolvectl >/dev/null 2>&1; then
  run resolvectl status
elif [ -r /etc/resolv.conf ]; then
  run cat /etc/resolv.conf
fi

section REACHABILITY
run sh -c 'command -v ping >/dev/null && ping -c 2 -W 2 1.1.1.1'
run sh -c 'command -v getent >/dev/null && getent hosts example.com'
