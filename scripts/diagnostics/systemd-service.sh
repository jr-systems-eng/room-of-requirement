#!/usr/bin/env bash
set -u

service="${1:-}"
[ -n "$service" ] || { echo "Usage: $0 <service>" >&2; exit 2; }

section() { printf '\n===== %s =====\n' "$1"; }
run() { printf '\n$ %s\n' "$*"; "$@" 2>&1 || true; }
summary_item() { printf '  [%-4s] %-22s %s\n' "$1" "$2" "$3"; }

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

section SUMMARY
if ! command -v systemctl >/dev/null 2>&1; then
  summary_item INFO 'systemd' 'systemctl is unavailable; no service interpretation performed'
  exit 0
fi

load_state="$(systemctl show "$service" -p LoadState --value 2>/dev/null || true)"
active_state="$(systemctl show "$service" -p ActiveState --value 2>/dev/null || true)"
sub_state="$(systemctl show "$service" -p SubState --value 2>/dev/null || true)"
exit_status="$(systemctl show "$service" -p ExecMainStatus --value 2>/dev/null || true)"

case "$load_state" in
  loaded) summary_item OK 'unit load state' 'loaded' ;;
  not-found|'') summary_item WARN 'unit load state' "${load_state:-not found}" ;;
  *) summary_item WARN 'unit load state' "$load_state" ;;
esac

case "$active_state" in
  active) summary_item OK 'service state' "active (${sub_state:-unknown})" ;;
  inactive) summary_item WARN 'service state' "inactive (${sub_state:-unknown})" ;;
  failed) summary_item WARN 'service state' "failed (${sub_state:-unknown})" ;;
  *) summary_item INFO 'service state' "${active_state:-unknown} (${sub_state:-unknown})" ;;
esac

if [[ "$exit_status" =~ ^[0-9]+$ ]]; then
  if [ "$exit_status" -eq 0 ]; then
    summary_item OK 'last main exit' '0'
  else
    summary_item WARN 'last main exit' "$exit_status"
  fi
fi

if [ "$active_state" != 'active' ] || { [[ "$exit_status" =~ ^[0-9]+$ ]] && [ "$exit_status" -ne 0 ]; }; then
  printf '\nSuggested next checks:\n'
  printf '  ror collect systemd %s\n' "$service"
  printf '  journalctl -u %s -b --no-pager\n' "$service"
  printf '  systemctl cat %s\n' "$service"
fi
