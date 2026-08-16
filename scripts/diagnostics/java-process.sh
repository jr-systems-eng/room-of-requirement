#!/usr/bin/env bash
set -u

pid="${1:-}"
summary_item() { printf '  [%-4s] %-22s %s\n' "$1" "$2" "$3"; }

echo '===== JAVA PROCESS DIAGNOSTIC ====='
date 2>/dev/null || true
hostname 2>/dev/null || true

printf '\n===== JAVA RUNTIME =====\n'
java_available='no'
if command -v java >/dev/null 2>&1; then
  java_available='yes'
  (java -version) 2>&1 || true
else
  echo 'java not found in PATH'
fi

printf '\n===== JAVA PROCESSES =====\n'
java_processes="$(pgrep -a java 2>/dev/null || ps -ef 2>/dev/null | grep '[j]ava' || true)"
printf '%s\n' "$java_processes"
process_count="$(printf '%s\n' "$java_processes" | sed '/^[[:space:]]*$/d' | wc -l | tr -d ' ')"

pid_found='not-requested'
pid_is_java='unknown'
if [ -n "$pid" ]; then
  if [ ! -d "/proc/$pid" ]; then
    pid_found='no'
  else
    pid_found='yes'
    cmdline="$(tr '\0' ' ' < "/proc/$pid/cmdline" 2>/dev/null || true)"
    case "$cmdline" in
      *java*) pid_is_java='yes' ;;
      *) pid_is_java='no' ;;
    esac

    printf '\n===== PROCESS %s =====\n' "$pid"
    ps -fp "$pid" 2>&1 || true
    printf '\n-- command line --\n'
    printf '%s\n' "$cmdline"
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
  fi
fi

printf '\n===== SUMMARY =====\n'
if [ "$java_available" = 'yes' ]; then
  summary_item OK 'Java runtime' 'java is available in PATH'
else
  summary_item WARN 'Java runtime' 'java is not available in PATH'
fi

if [ "$process_count" -gt 0 ]; then
  summary_item OK 'Java processes' "$process_count process(es) detected"
else
  summary_item INFO 'Java processes' 'no running Java process detected'
fi

if [ "$pid_found" = 'no' ]; then
  summary_item WARN 'requested PID' "$pid does not exist"
  printf '\nSuggested next checks:\n'
  printf '  pgrep -a java\n'
  printf '  ror diagnose java\n'
  exit 2
elif [ "$pid_found" = 'yes' ]; then
  summary_item OK 'requested PID' "$pid exists"
  case "$pid_is_java" in
    yes) summary_item OK 'process identity' 'command line appears to be Java' ;;
    no) summary_item WARN 'process identity' 'requested PID does not appear to be a Java process' ;;
  esac
  if command -v jcmd >/dev/null 2>&1; then
    summary_item OK 'JDK diagnostics' 'jcmd is available'
  else
    summary_item INFO 'JDK diagnostics' 'jcmd unavailable; runtime-only Java install may be in use'
  fi
fi
