#!/usr/bin/env bash
set -u

SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

section() {
  printf '\n===== %s =====\n' "$1"
}

run_collector() {
  local label="$1"
  local script="$2"
  shift 2
  section "$label"
  if [ -r "$SELF_DIR/$script" ]; then
    bash "$SELF_DIR/$script" "$@" 2>&1 || true
  else
    printf 'Collector unavailable: %s\n' "$script"
  fi
}

printf '===== ROR BASELINE COLLECTION =====\n'
date 2>/dev/null || true
hostname 2>/dev/null || true
printf 'Scope: read-only host intake. Likely-secret process environment blocks are intentionally excluded.\n'

run_collector SYSTEM system-info.sh
run_collector NETWORK network-info.sh
export ROR_STORAGE_SKIP_DU=1
run_collector STORAGE storage.sh
unset ROR_STORAGE_SKIP_DU
run_collector DNS dns.sh

section SECURITY
if command -v getenforce >/dev/null 2>&1; then
  printf 'SELinux: '
  getenforce 2>&1 || true
elif command -v aa-status >/dev/null 2>&1; then
  aa-status 2>&1 | head -40 || true
else
  printf 'SELinux/AppArmor status tool not found.\n'
fi

if command -v firewall-cmd >/dev/null 2>&1; then
  printf '\n-- firewalld --\n'
  firewall-cmd --state 2>&1 || true
  firewall-cmd --get-active-zones 2>&1 || true
elif command -v ufw >/dev/null 2>&1; then
  printf '\n-- ufw --\n'
  ufw status 2>&1 || true
fi

section TIME_SYNC
if command -v timedatectl >/dev/null 2>&1; then
  timedatectl 2>&1 || true
fi
if command -v chronyc >/dev/null 2>&1; then
  chronyc tracking 2>&1 || true
fi

section FAILED_SERVICES
if command -v systemctl >/dev/null 2>&1; then
  systemctl --failed --no-pager 2>&1 || true
fi

section RECENT_IMPORTANT_JOURNAL
if command -v journalctl >/dev/null 2>&1; then
  journalctl -p warning -n 100 --no-pager 2>&1 || true
fi

section KERNEL_PACKAGES
uname -r 2>/dev/null || true
if command -v rpm >/dev/null 2>&1; then
  rpm -qa 2>/dev/null | grep -E '^(kernel|kernel-core|kernel-uek|kernel-uek-core)-' | sort -V | tail -20 || true
elif command -v dpkg-query >/dev/null 2>&1; then
  dpkg-query -W -f='${Package} ${Version}\n' 'linux-image-*' 2>/dev/null | tail -20 || true
fi

section REBOOT_STATUS
if [ -f /var/run/reboot-required ]; then
  printf 'reboot-required: yes\n'
elif command -v needs-restarting >/dev/null 2>&1; then
  if needs-restarting -r >/dev/null 2>&1; then
    printf 'reboot-required: no (needs-restarting)\n'
  else
    printf 'reboot-required: yes or needs-restarting could not verify cleanly\n'
  fi
else
  printf 'reboot-required: unknown\n'
fi

section PROXY_PRESENCE
for name in HTTP_PROXY HTTPS_PROXY NO_PROXY http_proxy https_proxy no_proxy; do
  if [ -n "${!name:-}" ]; then
    printf '%-12s configured\n' "$name"
  fi
done

section BASELINE_END
date 2>/dev/null || true
