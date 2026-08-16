#!/usr/bin/env bash
set -u

summary_item() { printf '  [%-4s] %-22s %s\n' "$1" "$2" "$3"; }

echo '===== STORAGE DIAGNOSTIC ====='
date 2>/dev/null || true
hostname 2>/dev/null || true

printf '\n===== BLOCK DEVICES =====\n'
if command -v lsblk >/dev/null 2>&1; then
  lsblk -e7 -o NAME,TYPE,SIZE,FSTYPE,FSVER,LABEL,UUID,MOUNTPOINTS 2>&1 || lsblk 2>&1 || true
fi

printf '\n===== FILESYSTEM USAGE =====\n'
df -hT 2>&1 || df -h 2>&1 || true
printf '\n===== INODE USAGE =====\n'
df -hi 2>&1 || true

printf '\n===== MOUNTS =====\n'
findmnt 2>&1 || mount 2>&1 || true

printf '\n===== FSTAB =====\n'
[ -r /etc/fstab ] && cat /etc/fstab || true

printf '\n===== LVM =====\n'
for cmd in pvs vgs lvs; do
  if command -v "$cmd" >/dev/null 2>&1; then
    printf '\n-- %s --\n' "$cmd"
    "$cmd" 2>&1 || true
  fi
done

printf '\n===== LARGE TOP-LEVEL DIRECTORIES =====\n'
if [ "${ROR_STORAGE_SKIP_DU:-0}" = '1' ]; then
  echo 'Skipped for bounded collection. Run `ror diagnose storage` for the top-level du scan.'
elif command -v du >/dev/null 2>&1; then
  du -x -h --max-depth=1 / 2>/dev/null | sort -h | tail -n 20 || true
fi

open_deleted=''
printf '\n===== DELETED BUT OPEN FILES =====\n'
if command -v lsof >/dev/null 2>&1; then
  open_deleted="$(lsof +L1 2>/dev/null || true)"
  printf '%s\n' "$open_deleted" | head -n 80
else
  echo 'lsof not installed'
fi

printf '\n===== SUMMARY =====\n'
fs_warn=0
while IFS='|' read -r mount pct; do
  [ -n "$mount" ] || continue
  if [ "$pct" -ge 95 ]; then
    summary_item WARN 'filesystem usage' "$mount is ${pct}% used (critical pressure)"
    fs_warn=1
  elif [ "$pct" -ge 90 ]; then
    summary_item WARN 'filesystem usage' "$mount is ${pct}% used"
    fs_warn=1
  fi
done < <(df -P 2>/dev/null | awk 'NR>1 {gsub(/%/,"",$5); if ($5 ~ /^[0-9]+$/) print $6 "|" $5}')
[ "$fs_warn" -eq 0 ] && summary_item OK 'filesystem usage' 'no mounted filesystem at or above 90%'

inode_warn=0
while IFS='|' read -r mount pct; do
  [ -n "$mount" ] || continue
  if [ "$pct" -ge 90 ]; then
    summary_item WARN 'inode usage' "$mount is ${pct}% used"
    inode_warn=1
  fi
done < <(df -Pi 2>/dev/null | awk 'NR>1 {gsub(/%/,"",$5); if ($5 ~ /^[0-9]+$/) print $6 "|" $5}')
[ "$inode_warn" -eq 0 ] && summary_item OK 'inode usage' 'no mounted filesystem at or above 90%'

if [ -n "$open_deleted" ]; then
  deleted_count="$(printf '%s\n' "$open_deleted" | awk 'NR>1 {count++} END {print count+0}')"
  if [ "$deleted_count" -gt 0 ]; then
    summary_item WARN 'deleted open files' "$deleted_count open file handle(s) may still consume disk space"
  else
    summary_item OK 'deleted open files' 'none detected'
  fi
else
  if command -v lsof >/dev/null 2>&1; then
    summary_item OK 'deleted open files' 'none detected'
  else
    summary_item INFO 'deleted open files' 'lsof unavailable'
  fi
fi

if [ "$fs_warn" -ne 0 ] || [ "$inode_warn" -ne 0 ]; then
  printf '\nSuggested next checks:\n'
  printf '  ror find --type runbook filesystem\n'
  printf '  ror collect storage\n'
fi
