#!/usr/bin/env bash
set -u

SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
. "$SELF_DIR/common.sh"

usage() {
  cat <<'EOF'
Usage:
  ror workflow service-recovery --service NAME [--apply]

Default invocation inspects the unit and prints the restart/validation plan.
--apply performs only a systemctl restart; it does not edit unit/configuration files.
EOF
}

service='' apply='no'
while [ "$#" -gt 0 ]; do
  case "$1" in
    --service) service="${2:-}"; shift 2 ;;
    --apply) apply='yes'; shift ;;
    --help|-h) usage; exit 0 ;;
    *) printf 'Unknown option: %s\n' "$1" >&2; usage >&2; exit 2 ;;
  esac
done
[ -n "$service" ] || { usage >&2; exit 2; }
workflow_no_whitespace "$service" || { printf 'Whitespace is not valid in a systemd unit name.\n' >&2; exit 2; }

preflight_failed=0
workflow_section 'Preflight'
if workflow_have systemctl; then
  workflow_item OK 'systemctl' 'available'
else
  workflow_item FAIL 'systemctl' 'required'
  preflight_failed=1
fi

if [ "$preflight_failed" -eq 0 ]; then
  load_state="$(systemctl show "$service" -p LoadState --value 2>/dev/null || true)"
  active_state="$(systemctl show "$service" -p ActiveState --value 2>/dev/null || true)"
  sub_state="$(systemctl show "$service" -p SubState --value 2>/dev/null || true)"
  fragment="$(systemctl show "$service" -p FragmentPath --value 2>/dev/null || true)"
  if [ "$load_state" = 'loaded' ]; then
    workflow_item OK 'unit load state' "$load_state"
  else
    workflow_item FAIL 'unit load state' "${load_state:-unknown}"
    preflight_failed=1
  fi
  workflow_item INFO 'current state' "${active_state:-unknown}/${sub_state:-unknown}"
  [ -n "$fragment" ] && workflow_item INFO 'unit file' "$fragment"

  printf '\nCurrent status:\n'
  systemctl status "$service" --no-pager -l 2>&1 | sed 's/^/  /' || true

  if [ -n "$fragment" ] && workflow_have systemd-analyze; then
    if systemd-analyze verify "$fragment" >/dev/null 2>&1; then
      workflow_item OK 'unit verification' 'systemd-analyze verify passed for fragment'
    else
      workflow_item WARN 'unit verification' 'systemd-analyze verify reported findings; inspect before restart'
    fi
  fi
fi

if workflow_can_elevate; then
  workflow_item OK 'privilege' 'root or sudo available for apply'
else
  workflow_item WARN 'privilege' 'no root/sudo path available; plan remains read-only'
  [ "$apply" = 'yes' ] && preflight_failed=1
fi

workflow_section 'Plan'
printf '  1. Preserve the current unit/configuration; this workflow does not edit it.\n'
printf '  2. Restart only the requested unit: %s\n' "$service"
printf '  3. Verify ActiveState/SubState and systemctl is-active.\n'
printf '  4. Show the most recent unit journal entries for post-restart evidence.\n'

if [ "$apply" != 'yes' ]; then
  printf '\n'
  workflow_plan_only_banner
  [ "$preflight_failed" -eq 0 ] || printf 'Preflight contains blocking findings that must be resolved before apply.\n'
  exit 0
fi
[ "$preflight_failed" -eq 0 ] || { printf 'Refusing apply because preflight has blocking findings.\n' >&2; exit 1; }

workflow_section 'Apply'
workflow_run_root systemctl restart "$service"
workflow_item OK 'restart' 'systemctl restart completed'

workflow_section 'Validation'
new_active="$(systemctl show "$service" -p ActiveState --value 2>/dev/null || true)"
new_sub="$(systemctl show "$service" -p SubState --value 2>/dev/null || true)"
printf '  Active/SubState: %s/%s\n' "$new_active" "$new_sub"
if systemctl is-active --quiet "$service"; then
  workflow_item OK 'service state' 'active'
else
  workflow_item FAIL 'service state' 'not active after restart'
  systemctl status "$service" --no-pager -l 2>&1 | sed 's/^/  /' || true
  exit 1
fi
if workflow_have journalctl; then
  journalctl -u "$service" -n 30 --no-pager 2>&1 | sed 's/^/  /' || true
fi

workflow_section 'Rollback guidance'
printf '  This workflow changes no files, so there is no configuration backup to restore.\n'
printf '  A process restart itself is not reversible; if the service is unhealthy, use the captured status/journal evidence and the relevant runbook before further changes.\n'
