#!/usr/bin/env bash
set -u

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
if command -v du >/dev/null 2>&1; then
  du -x -h --max-depth=1 / 2>/dev/null | sort -h | tail -n 20 || true
fi

printf '\n===== DELETED BUT OPEN FILES =====\n'
if command -v lsof >/dev/null 2>&1; then
  lsof +L1 2>/dev/null | head -n 80 || true
else
  echo 'lsof not installed'
fi
