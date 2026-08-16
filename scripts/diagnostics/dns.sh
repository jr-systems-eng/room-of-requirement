#!/usr/bin/env bash
set -u

name="${1:-}"

echo '===== DNS DIAGNOSTIC ====='
date 2>/dev/null || true
hostname 2>/dev/null || true

printf '\n===== RESOLVER CONFIG =====\n'
[ -r /etc/resolv.conf ] && cat /etc/resolv.conf || true

printf '\n===== HOSTS FILE =====\n'
[ -r /etc/hosts ] && cat /etc/hosts || true

printf '\n===== RESOLVER STATUS =====\n'
if command -v resolvectl >/dev/null 2>&1; then
  resolvectl status 2>&1 || true
elif command -v systemd-resolve >/dev/null 2>&1; then
  systemd-resolve --status 2>&1 || true
fi

[ -n "$name" ] || exit 0

printf '\n===== LOOKUP: %s =====\n' "$name"
if command -v getent >/dev/null 2>&1; then
  printf '\n-- getent ahosts --\n'
  getent ahosts "$name" 2>&1 || true
fi
if command -v dig >/dev/null 2>&1; then
  printf '\n-- dig A/AAAA --\n'
  dig "$name" A +noall +answer +comments 2>&1 || true
  dig "$name" AAAA +noall +answer +comments 2>&1 || true
  printf '\n-- dig trace summary --\n'
  dig "$name" +trace +nodnssec 2>&1 | tail -n 30 || true
elif command -v nslookup >/dev/null 2>&1; then
  nslookup "$name" 2>&1 || true
else
  echo 'Neither dig nor nslookup is available.'
fi
