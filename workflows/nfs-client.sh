#!/usr/bin/env bash
set -u

SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
. "$SELF_DIR/common.sh"

usage() {
  cat <<'EOF'
Usage:
  ror workflow nfs-client --server HOST --export /PATH --mountpoint /PATH [options]

Options:
  --options OPTS   NFS mount options (default: vers=4)
  --persist        Also add a guarded /etc/fstab entry using systemd automount-friendly options
  --apply          Perform the planned mount/configuration
  --help

Default invocation performs preflight and prints the exact plan without changing the host.
EOF
}

server='' export_path='' mountpoint='' options='vers=4' persist='no' apply='no'
while [ "$#" -gt 0 ]; do
  case "$1" in
    --server) server="${2:-}"; shift 2 ;;
    --export) export_path="${2:-}"; shift 2 ;;
    --mountpoint) mountpoint="${2:-}"; shift 2 ;;
    --options) options="${2:-}"; shift 2 ;;
    --persist) persist='yes'; shift ;;
    --apply) apply='yes'; shift ;;
    --help|-h) usage; exit 0 ;;
    *) printf 'Unknown option: %s\n' "$1" >&2; usage >&2; exit 2 ;;
  esac
done

[ -n "$server" ] && [ -n "$export_path" ] && [ -n "$mountpoint" ] || { usage >&2; exit 2; }
case "$export_path" in /*) ;; *) printf 'Export must be an absolute NFS export path.\n' >&2; exit 2 ;; esac
for value in "$server" "$export_path" "$mountpoint" "$options"; do
  workflow_no_whitespace "$value" || { printf 'Whitespace is not supported in Phase 8 NFS workflow arguments.\n' >&2; exit 2; }
done

source_spec="${server}:${export_path}"
preflight_failed=0
mount_exists='no'
created_dir='no'
fstab_existing=''

workflow_section 'Preflight'
if [ "$(uname -s 2>/dev/null || true)" = 'Linux' ]; then
  workflow_item OK 'platform' 'Linux'
else
  workflow_item FAIL 'platform' 'NFS apply workflow currently supports Linux only'
  preflight_failed=1
fi

if workflow_have mount.nfs || workflow_have mount.nfs4; then
  workflow_item OK 'NFS mount helper' 'available'
else
  workflow_item FAIL 'NFS mount helper' 'install nfs-utils (RPM family) or nfs-common (Debian family) first'
  preflight_failed=1
fi

if workflow_have findmnt; then
  workflow_item OK 'findmnt' 'available'
else
  workflow_item FAIL 'findmnt' 'required for guarded mount validation'
  preflight_failed=1
fi

if workflow_have getent && getent ahosts "$server" >/dev/null 2>&1; then
  workflow_item OK 'server resolution' "$server resolves"
elif workflow_have getent; then
  workflow_item WARN 'server resolution' "$server did not resolve through getent"
else
  workflow_item INFO 'server resolution' 'getent unavailable; skipped'
fi

if workflow_have nc; then
  if nc -z -w 2 "$server" 2049 >/dev/null 2>&1; then
    workflow_item OK 'TCP/2049' 'reachable'
  else
    workflow_item WARN 'TCP/2049' 'not confirmed reachable; this does not prove the export is invalid'
  fi
else
  workflow_item INFO 'TCP/2049' 'nc unavailable; skipped'
fi

if [ -e "$mountpoint" ]; then
  if [ ! -d "$mountpoint" ]; then
    workflow_item FAIL 'mountpoint' 'exists but is not a directory'
    preflight_failed=1
  elif workflow_have findmnt && findmnt -rn -M "$mountpoint" >/dev/null 2>&1; then
    current_mount="$(findmnt -rn -M "$mountpoint" -o SOURCE,FSTYPE 2>/dev/null || true)"
    workflow_item INFO 'existing mount' "${current_mount:-mounted}"
    mount_exists='yes'
  elif [ -n "$(find "$mountpoint" -mindepth 1 -maxdepth 1 -print -quit 2>/dev/null)" ]; then
    workflow_item FAIL 'mountpoint contents' 'directory is non-empty and is not currently a mountpoint'
    preflight_failed=1
  else
    workflow_item OK 'mountpoint' 'existing empty directory'
  fi
else
  workflow_item OK 'mountpoint' 'will be created during apply'
fi

if [ "$persist" = 'yes' ]; then
  if [ -r /etc/fstab ]; then
    fstab_existing="$(awk -v mp="$mountpoint" '$1 !~ /^#/ && $2==mp {print; exit}' /etc/fstab 2>/dev/null || true)"
    if [ -n "$fstab_existing" ]; then
      existing_source="$(printf '%s\n' "$fstab_existing" | awk '{print $1}')"
      if [ "$existing_source" = "$source_spec" ]; then
        workflow_item INFO 'fstab' 'mountpoint already has matching source; no duplicate entry will be added'
      else
        workflow_item FAIL 'fstab' "mountpoint already configured: $fstab_existing"
        preflight_failed=1
      fi
    else
      workflow_item OK 'fstab' 'no conflicting entry found'
    fi
  else
    workflow_item FAIL 'fstab' '/etc/fstab is not readable'
    preflight_failed=1
  fi
fi

if workflow_can_elevate; then
  workflow_item OK 'privilege' 'root or sudo available for apply'
else
  workflow_item WARN 'privilege' 'no root/sudo path available; plan is still usable but apply will fail'
  [ "$apply" = 'yes' ] && preflight_failed=1
fi

workflow_section 'Plan'
printf '  1. Ensure mountpoint exists: %s\n' "$mountpoint"
if [ "$mount_exists" = 'yes' ]; then
  printf '  2. Leave the existing mount untouched and validate it against the requested source.\n'
else
  printf '  2. Mount %s at %s as NFS with options: %s\n' "$source_spec" "$mountpoint" "$options"
fi
printf '  3. Validate the mounted source/filesystem with findmnt.\n'
if [ "$persist" = 'yes' ]; then
  printf '  4. Back up /etc/fstab before any edit.\n'
  printf '  5. Add a single persistent entry only if the mountpoint is not already configured.\n'
  printf '     Persistent options: %s,_netdev,nofail,x-systemd.automount\n' "$options"
  printf '  6. Reload systemd manager configuration when systemd is available.\n'
else
  printf '  4. Do not change /etc/fstab.\n'
fi

if [ "$apply" != 'yes' ]; then
  printf '\n'
  workflow_plan_only_banner
  [ "$preflight_failed" -eq 0 ] || printf 'Preflight contains blocking findings that must be resolved before apply.\n'
  exit 0
fi

[ "$preflight_failed" -eq 0 ] || { printf 'Refusing apply because preflight has blocking findings.\n' >&2; exit 1; }

workflow_section 'Apply'
if [ ! -d "$mountpoint" ]; then
  workflow_run_root mkdir -p "$mountpoint"
  created_dir='yes'
  workflow_item OK 'mountpoint' 'created'
fi

if [ "$mount_exists" != 'yes' ]; then
  workflow_run_root mount -t nfs -o "$options" "$source_spec" "$mountpoint"
  workflow_item OK 'mount' 'mount command completed'
fi

actual="$(findmnt -rn -M "$mountpoint" -o SOURCE,FSTYPE,OPTIONS 2>/dev/null || true)"
if [ -z "$actual" ]; then
  workflow_item FAIL 'mount validation' 'findmnt did not confirm the mountpoint'
  exit 1
fi
workflow_item OK 'mount validation' "$actual"

backup=''
if [ "$persist" = 'yes' ] && [ -z "$fstab_existing" ]; then
  backup="/etc/fstab.ror-$(date +%Y%m%d-%H%M%S).bak"
  workflow_run_root cp -a /etc/fstab "$backup"
  persistent_options="${options},_netdev,nofail,x-systemd.automount"
  fstab_line="$source_spec $mountpoint nfs $persistent_options 0 0"
  workflow_append_root "$fstab_line" /etc/fstab
  workflow_item OK 'fstab backup' "$backup"
  workflow_item OK 'fstab entry' "$fstab_line"
  if workflow_have systemctl; then
    workflow_run_root systemctl daemon-reload
  fi
fi

workflow_section 'Validation'
findmnt -rn -M "$mountpoint" -o TARGET,SOURCE,FSTYPE,OPTIONS
if [ "$persist" = 'yes' ]; then
  awk -v mp="$mountpoint" '$1 !~ /^#/ && $2==mp {print}' /etc/fstab
fi

workflow_section 'Rollback guidance'
printf '  Unmount: %s\n' "$(workflow_is_root && printf 'umount' || printf 'sudo umount') $mountpoint"
if [ -n "$backup" ]; then
  printf '  Restore fstab: %s\n' "$(workflow_is_root && printf 'cp -a' || printf 'sudo cp -a') $backup /etc/fstab"
  workflow_have systemctl && printf '  Then reload systemd: %s\n' "$(workflow_is_root && printf 'systemctl' || printf 'sudo systemctl') daemon-reload"
fi
if [ "$created_dir" = 'yes' ]; then
  printf '  After unmount, remove the directory only if it is still empty: %s\n' "$mountpoint"
fi
