#!/usr/bin/env bash
set -u

pid="${1:-}"

echo '===== JAVA PROCESS DIAGNOSTIC ====='
date 2>/dev/null || true
hostname 2>/dev/null || true

printf '\n===== JAVA RUNTIME =====\n'
(java -version) 2>&1 || true
printf '\n===== JAVA PROCESSES =====\n'
pgrep -a java 2>/dev/null || ps -ef 2>/dev/null | grep '[j]ava' || true

[ -n "$pid" ] || exit 0
[ -d "/proc/$pid" ] || { echo "PID not found: $pid" >&2; exit 2; }

printf '\n===== PROCESS %s =====\n' "$pid"
ps -fp "$pid" 2>&1 || true
printf '\n-- command line --\n'
tr '\0' ' ' < "/proc/$pid/cmdline" 2>/dev/null; printf '\n'
printf '\n-- executable / cwd --\n'
readlink -f "/proc/$pid/exe" 2>/dev/null || true
readlink -f "/proc/$pid/cwd" 2>/dev/null || true
printf '\n-- limits --\n'
cat "/proc/$pid/limits" 2>/dev/null || true

printf '\n===== JVM DETAILS =====\n'
if command -v jcmd >/dev/null 2>&1; then
  jcmd "$pid" VM.version 2>&1 || true
  jcmd "$pid" VM.command_line 2>&1 || true
  jcmd "$pid" VM.flags 2>&1 || true
  jcmd "$pid" GC.heap_info 2>&1 || true
else
  echo 'jcmd not installed/available'
fi

printf '\n===== LISTENING / ESTABLISHED SOCKETS =====\n'
if command -v lsof >/dev/null 2>&1; then
  lsof -Pan -p "$pid" -i 2>/dev/null || true
fi

printf '\n===== OPEN JAR / CONFIG-LIKE FILES =====\n'
if command -v lsof >/dev/null 2>&1; then
  lsof -p "$pid" 2>/dev/null | grep -Ei '\.(jar|war|ear|xml|properties|yml|yaml|conf)([[:space:]]|$)' | head -n 100 || true
fi
