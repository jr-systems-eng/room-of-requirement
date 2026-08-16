#!/usr/bin/env bash
set -u

service="${1:-tomcat}"

echo '===== TOMCAT DIAGNOSTIC ====='
date 2>/dev/null || true
hostname 2>/dev/null || true

printf '\n===== SERVICE =====\n'
if command -v systemctl >/dev/null 2>&1; then
  systemctl status "$service" --no-pager -l 2>&1 || true
  systemctl show "$service" -p MainPID -p ExecStart -p User -p Group -p Environment --no-pager 2>&1 || true
fi

printf '\n===== TOMCAT / JAVA PROCESSES =====\n'
ps -ef 2>/dev/null | grep -E '[o]rg\.apache\.catalina|[t]omcat' || true

pid=''
if command -v systemctl >/dev/null 2>&1; then
  pid="$(systemctl show "$service" -p MainPID --value 2>/dev/null || true)"
  [ "$pid" = '0' ] && pid=''
fi
if [ -z "$pid" ]; then
  pid="$(pgrep -f 'org\.apache\.catalina\.startup\.Bootstrap' 2>/dev/null | head -n1 || true)"
fi

printf '\n===== COMMON LOCATIONS =====\n'
for path in /etc/tomcat /etc/tomcat9 /etc/tomcat10 /var/log/tomcat /var/log/tomcat9 /var/lib/tomcat /opt/tomcat; do
  [ -e "$path" ] && ls -ld "$path" 2>&1 || true
done

if [ -n "$pid" ] && [ -d "/proc/$pid" ]; then
  printf '\n===== PROCESS %s =====\n' "$pid"
  ps -fp "$pid" 2>&1 || true
  printf '\n-- command line --\n'
  tr '\0' ' ' < "/proc/$pid/cmdline" 2>/dev/null; printf '\n'
  printf '\n-- cwd --\n'
  readlink -f "/proc/$pid/cwd" 2>/dev/null || true
  if command -v lsof >/dev/null 2>&1; then
    printf '\n-- network sockets --\n'
    lsof -Pan -p "$pid" -i 2>/dev/null || true
  fi
fi

printf '\n===== RECENT JOURNAL =====\n'
if command -v journalctl >/dev/null 2>&1; then
  journalctl -u "$service" -n 100 --no-pager 2>&1 || true
fi

printf '\n===== CATALINA LOG CANDIDATES =====\n'
for log in /var/log/tomcat/catalina.out /var/log/tomcat9/catalina.out /opt/tomcat/logs/catalina.out; do
  if [ -r "$log" ]; then
    echo "-- $log --"
    tail -n 80 "$log" 2>&1 || true
  fi
done
