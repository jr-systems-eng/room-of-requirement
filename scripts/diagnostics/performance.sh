#!/usr/bin/env bash
set -u

section() { printf '\n===== %s =====\n' "$1"; }
have() { command -v "$1" >/dev/null 2>&1; }

host="$(hostname -f 2>/dev/null || hostname 2>/dev/null || printf unknown)"
cpu_count='unknown'
load1=''
blocked_count='unknown'
mem_used_pct=''
oom_count='unknown'

if have nproc; then
  cpu_count="$(nproc 2>/dev/null || printf unknown)"
elif have getconf; then
  cpu_count="$(getconf _NPROCESSORS_ONLN 2>/dev/null || printf unknown)"
fi

if [ -r /proc/loadavg ]; then
  load1="$(awk '{print $1}' /proc/loadavg 2>/dev/null)"
fi

if [ -r /proc/meminfo ]; then
  mem_used_pct="$(awk '
    /^MemTotal:/ {total=$2}
    /^MemAvailable:/ {avail=$2}
    END {if (total > 0 && avail >= 0) printf "%.0f", ((total-avail)*100)/total}
  ' /proc/meminfo)"
fi

if have ps; then
  blocked_count="$(ps -eo state= 2>/dev/null | awk '$1 ~ /^D/ {count++} END {print count+0}')"
fi

if have journalctl; then
  oom_count="$(journalctl -k -b --no-pager 2>/dev/null | grep -ciE 'out of memory|oom-kill|killed process' || true)"
fi

printf 'ROR performance diagnostic\n'
printf 'Host: %s\n' "$host"
printf 'Date: %s\n' "$(date -Is 2>/dev/null || date)"

section 'LOAD / UPTIME'
uptime 2>/dev/null || true
[ -r /proc/loadavg ] && cat /proc/loadavg || true
printf 'Online CPUs: %s\n' "$cpu_count"

section 'CPU / PROCESS SNAPSHOT'
if have ps; then
  ps -eo pid,ppid,user,stat,%cpu,%mem,etime,comm,args --sort=-%cpu 2>/dev/null | head -n 25 || true
else
  printf 'ps unavailable\n'
fi

section 'MEMORY / SWAP'
if have free; then
  free -h 2>/dev/null || true
fi
if [ -r /proc/meminfo ]; then
  grep -E '^(MemTotal|MemAvailable|SwapTotal|SwapFree|Dirty|Writeback|Slab|SReclaimable|SUnreclaim):' /proc/meminfo || true
fi

section 'VMSTAT'
if have vmstat; then
  vmstat 1 3 2>/dev/null || true
else
  printf 'vmstat unavailable\n'
fi

section 'BLOCKED TASKS'
if have ps; then
  ps -eo state,pid,ppid,wchan:32,comm,args 2>/dev/null | awk 'NR==1 || $1 ~ /^D/' || true
else
  printf 'ps unavailable\n'
fi

section 'I/O SNAPSHOT'
if have iostat; then
  iostat -xz 1 2 2>/dev/null || true
else
  printf 'iostat unavailable (install sysstat when deeper I/O evidence is needed)\n'
fi

section 'RECENT OOM / KERNEL MEMORY EVENTS'
if have journalctl; then
  journalctl -k -b --no-pager 2>/dev/null | grep -iE 'out of memory|oom-kill|killed process' | tail -n 30 || true
else
  printf 'journalctl unavailable\n'
fi

section 'SUMMARY'
if [ -n "$load1" ] && [[ "$cpu_count" =~ ^[0-9]+$ ]]; then
  if awk -v load="$load1" -v cpus="$cpu_count" 'BEGIN {exit !(load >= cpus)}'; then
    printf '[WARN] 1-minute load (%s) is at or above online CPU count (%s); distinguish CPU saturation from blocked work using the evidence above.\n' "$load1" "$cpu_count"
  else
    printf '[OK]   1-minute load (%s) is below online CPU count (%s).\n' "$load1" "$cpu_count"
  fi
else
  printf '[INFO] load/CPU comparison unavailable on this platform.\n'
fi

if [[ "$mem_used_pct" =~ ^[0-9]+$ ]]; then
  if [ "$mem_used_pct" -ge 90 ]; then
    printf '[WARN] MemAvailable indicates approximately %s%% of RAM is currently unavailable.\n' "$mem_used_pct"
  else
    printf '[OK]   MemAvailable indicates approximately %s%% of RAM is currently unavailable.\n' "$mem_used_pct"
  fi
else
  printf '[INFO] Linux MemAvailable percentage unavailable.\n'
fi

if [[ "$blocked_count" =~ ^[0-9]+$ ]]; then
  if [ "$blocked_count" -gt 0 ]; then
    printf '[WARN] %s task(s) are currently in uninterruptible D state; investigate I/O or kernel waits.\n' "$blocked_count"
  else
    printf '[OK]   No D-state tasks observed in this snapshot.\n'
  fi
fi

if [[ "$oom_count" =~ ^[0-9]+$ ]] && [ "$oom_count" -gt 0 ]; then
  printf '[WARN] %s OOM-related kernel log line(s) were observed in the current boot. Correlate timestamps and affected processes before changing limits.\n' "$oom_count"
else
  printf '[INFO] No OOM-related kernel log lines were observed, or kernel journal data was unavailable.\n'
fi

printf '[INFO] Summary signals are observations, not a proven root cause.\n'
