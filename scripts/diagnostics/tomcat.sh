#!/usr/bin/env bash
set -u

service="${1:-tomcat}"
summary_item() { printf '  [%-4s] %-22s %s\n' "$1" "$2" "$3"; }

echo '===== TOMCAT DIAGNOSTIC ====='
date 2>/dev/null || true
hostname 2>/dev/null || true

printf '\n===== SERVICE =====\n'
if command -v systemctl >/dev/null 2>&1; then
  systemctl status "$service" --no-pager -l 2>&1 || true
  # Deliberately exclude Environment: service environments may contain secrets.
  systemctl show "$service" -p LoadState -p ActiveState -p SubState -p MainPID -p ExecStart -p User -p Group --no-pager 2>&1 || true
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

log_scan=''
printf '\n===== RECENT JOURNAL =====\n'
if command -v journalctl >/dev/null 2>&1; then
  recent_journal="$(journalctl -u "$service" -n 100 --no-pager 2>&1 || true)"
  printf '%s\n' "$recent_journal"
  log_scan="$recent_journal"
fi

printf '\n===== CATALINA LOG CANDIDATES =====\n'
for log in /var/log/tomcat/catalina.out /var/log/tomcat9/catalina.out /opt/tomcat/logs/catalina.out; do
  if [ -r "$log" ]; then
    echo "-- $log --"
    log_tail="$(tail -n 80 "$log" 2>&1 || true)"
    printf '%s\n' "$log_tail"
    log_scan="$log_scan
$log_tail"
  fi
done

printf '\n===== SUMMARY =====\n'
if command -v systemctl >/dev/null 2>&1; then
  if systemctl is-active --quiet "$service" 2>/dev/null; then
    summary_item OK 'service' "$service is active"
  else
    summary_item WARN 'service' "$service is not active through systemd"
  fi
else
  summary_item INFO 'service' 'systemctl unavailable'
fi

if [ -n "$pid" ] && [ -d "/proc/$pid" ]; then
  summary_item OK 'Tomcat process' "PID $pid detected"
else
  summary_item WARN 'Tomcat process' 'no Tomcat Bootstrap PID detected'
fi

pattern_count=0
if [ -n "$log_scan" ]; then
  if printf '%s\n' "$log_scan" | grep -qi 'OutOfMemoryError'; then
    summary_item WARN 'recent log pattern' 'Java OutOfMemoryError detected'
    pattern_count=$((pattern_count + 1))
  fi
  if printf '%s\n' "$log_scan" | grep -qiE 'PKIX path building failed|unable to find valid certification path'; then
    summary_item WARN 'recent log pattern' 'Java certificate trust / PKIX failure detected'
    pattern_count=$((pattern_count + 1))
  fi
  if printf '%s\n' "$log_scan" | grep -qiE 'Address already in use|BindException'; then
    summary_item WARN 'recent log pattern' 'listener bind/port conflict detected'
    pattern_count=$((pattern_count + 1))
  fi
  if printf '%s\n' "$log_scan" | grep -qiE 'Connection refused|ConnectException'; then
    summary_item WARN 'recent log pattern' 'downstream connection failure detected'
    pattern_count=$((pattern_count + 1))
  fi
  if [ "$pattern_count" -eq 0 ]; then
    summary_item INFO 'recent log patterns' 'no selected high-signal pattern found in sampled logs'
  fi
else
  summary_item INFO 'recent logs' 'no readable journal/catalina sample available'
fi

if [ -z "$pid" ] || [ "$pattern_count" -gt 0 ]; then
  printf '\nSuggested next checks:\n'
  printf '  ror find --type runbook systemd\n'
  printf '  ror find --type runbook java\n'
  printf '  ror collect tomcat %s\n' "$service"
fi
