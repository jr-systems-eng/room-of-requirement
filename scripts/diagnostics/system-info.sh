#!/usr/bin/env bash
set -u

section() { printf '\n===== %s =====\n' "$1"; }
run() { printf '\n$ %s\n' "$*"; "$@" 2>&1 || true; }

section HOST
run hostname
run uname -a
[ -r /etc/os-release ] && run cat /etc/os-release
run uptime

section IDENTITY
run id
run who

section CPU_MEMORY
run sh -c 'command -v lscpu >/dev/null && lscpu | head -40'
run sh -c 'command -v free >/dev/null && free -h'

section STORAGE
run df -hT
run sh -c 'command -v lsblk >/dev/null && lsblk -f'

section NETWORK
run sh -c 'command -v ip >/dev/null && ip -brief addr'
run sh -c 'command -v ip >/dev/null && ip route'
run sh -c 'command -v ss >/dev/null && ss -lntup'

section SERVICES
run sh -c 'command -v systemctl >/dev/null && systemctl --failed --no-pager'

section TIME
run date
run sh -c 'command -v timedatectl >/dev/null && timedatectl'
