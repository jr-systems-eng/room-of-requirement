#!/usr/bin/env bash
set -u

service="${1:-sshd}"

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

printf '\n===== LISTENERS =====\n'
if command -v ss >/dev/null 2>&1; then
  ss -lntp 2>&1 | grep -E '(^State|:22[[:space:]])' || true
elif command -v netstat >/dev/null 2>&1; then
  netstat -lntp 2>&1 | grep -E '(^Proto|:22[[:space:]])' || true
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

printf '\n===== RECENT LOGS =====\n'
if command -v journalctl >/dev/null 2>&1; then
  journalctl -u "$service" -n 80 --no-pager 2>&1 || true
fi
