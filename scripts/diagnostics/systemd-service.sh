#!/usr/bin/env bash
set -u

service="${1:-}"
[ -n "$service" ] || { echo "Usage: $0 <service>" >&2; exit 2; }

section() { printf '\n===== %s =====\n' "$1"; }
run() { printf '\n$ %s\n' "$*"; "$@" 2>&1 || true; }

section STATUS
run systemctl status "$service" --no-pager -l

section UNIT
run systemctl cat "$service"

section PROPERTIES
run systemctl show "$service" -p LoadState -p ActiveState -p SubState -p FragmentPath -p MainPID -p ExecMainStatus

section RECENT_LOGS
run journalctl -u "$service" -n 100 --no-pager

section FAILED_UNITS
run systemctl --failed --no-pager
