#!/usr/bin/env bash
set -u

service="${1:-sshd}"
summary_item() { printf '  [%-4s] %-22s %s\n' "$1" "$2" "$3"; }

echo '===== SSH SERVER DIAGNOSTIC ====='
date 2>/dev/null || true
hostname 2>/dev/null || true

printf '\n===== VERSION =====\n'
(ssh -V) 2>&1 || true
(sshd -V) 2>&1 || true

printf '\n===== SERVICE =====\n'
if command -v systemctl >/dev/null 2>&1; then
  systemctl status "$service" --no-pager -l 2>&1 || true
  printf '\n-- enabled/state --\n'
  systemctl is-enabled "$service" 2>&1 || true
  systemctl is-active "$service" 2>&1 || true
fi

port=22
if command -v sshd >/dev/null 2>&1; then
  detected_port="$(sshd -T 2>/dev/null | awk '$1 == "port" {print $2; exit}')"
  [ -n "$detected_port" ] && port="$detected_port"
fi

printf '\n===== LISTENERS =====\n'
if command -v ss >/dev/null 2>&1; then
  ss -lntp 2>&1 | grep -E "(^State|:${port}([[:space:]]|$))" || true
elif command -v netstat >/dev/null 2>&1; then
  netstat -lntp 2>&1 | grep -E "(^Proto|:${port}([[:space:]]|$))" || true
fi

printf '\n===== CONFIG VALIDATION =====\n'
if command -v sshd >/dev/null 2>&1; then
  sshd -t 2>&1 || true
else
  echo 'sshd not found in PATH'
fi

printf '\n===== EFFECTIVE SSHD CONFIG =====\n'
if command -v sshd >/dev/null 2>&1; then
  sshd -T 2>&1 | grep -Ei '^(port|listenaddress|passwordauthentication|pubkeyauthentication|kbdinteractiveauthentication|challengeresponseauthentication|usepam|permitrootlogin|authenticationmethods|subsystem|kexalgorithms|ciphers|macs|hostkeyalgorithms) ' || true
else
  echo 'sshd not found in PATH'
fi

printf '\n===== CONFIG FILES =====\n'
for path in /etc/ssh/sshd_config /etc/ssh/sshd_config.d; do
  [ -e "$path" ] && ls -ld "$path" 2>&1 || true
done
if [ -d /etc/ssh/sshd_config.d ]; then
  find /etc/ssh/sshd_config.d -maxdepth 1 -type f -printf '%f\n' 2>/dev/null | sort || true
fi

recent_logs=''
printf '\n===== RECENT LOGS =====\n'
if command -v journalctl >/dev/null 2>&1; then
  recent_logs="$(journalctl -u "$service" -n 80 --no-pager 2>&1 || true)"
  printf '%s\n' "$recent_logs"
fi

printf '\n===== SUMMARY =====\n'
if command -v systemctl >/dev/null 2>&1; then
  if systemctl is-active --quiet "$service" 2>/dev/null; then
    summary_item OK 'service' "$service is active"
  else
    summary_item WARN 'service' "$service is not active"
  fi
else
  summary_item INFO 'service' 'systemctl unavailable'
fi

if command -v sshd >/dev/null 2>&1; then
  if sshd -t >/dev/null 2>&1; then
    summary_item OK 'config syntax' 'sshd -t passed'
  else
    summary_item WARN 'config syntax' 'sshd -t failed; inspect validation output above'
  fi
else
  summary_item INFO 'config syntax' 'sshd unavailable'
fi

listener='unknown'
if command -v ss >/dev/null 2>&1; then
  if ss -lnt 2>/dev/null | grep -Eq ":${port}([[:space:]]|$)"; then listener='yes'; else listener='no'; fi
elif command -v netstat >/dev/null 2>&1; then
  if netstat -lnt 2>/dev/null | grep -Eq ":${port}([[:space:]]|$)"; then listener='yes'; else listener='no'; fi
fi
case "$listener" in
  yes) summary_item OK 'listener' "TCP port $port is listening" ;;
  no) summary_item WARN 'listener' "no TCP listener detected on port $port" ;;
  *) summary_item INFO 'listener' 'socket-listing tool unavailable' ;;
esac

if [ -n "$recent_logs" ]; then
  if printf '%s\n' "$recent_logs" | grep -qi 'no matching key exchange method found'; then
    summary_item WARN 'recent log pattern' 'SSH key-exchange mismatch detected'
  fi
  if printf '%s\n' "$recent_logs" | grep -qi 'DH GEX group out of range'; then
    summary_item WARN 'recent log pattern' 'Diffie-Hellman group-exchange range mismatch detected'
  fi
  if printf '%s\n' "$recent_logs" | grep -qiE 'permission denied|authentication failure|failed password|pam_.*auth'; then
    summary_item WARN 'recent log pattern' 'authentication/PAM failures detected'
  fi
  if printf '%s\n' "$recent_logs" | grep -qi 'subsystem request for sftp'; then
    summary_item INFO 'recent log pattern' 'SFTP subsystem requests observed'
  fi
fi

if [ "$listener" = 'no' ] || ! { command -v systemctl >/dev/null 2>&1 && systemctl is-active --quiet "$service" 2>/dev/null; }; then
  printf '\nSuggested next checks:\n'
  printf '  ror find --type runbook ssh\n'
  printf '  journalctl -u %s -b --no-pager\n' "$service"
  printf '  sshd -T | less\n'
fi
