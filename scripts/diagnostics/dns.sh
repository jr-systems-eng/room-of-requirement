#!/usr/bin/env bash
set -u

name="${1:-}"
summary_item() { printf '  [%-4s] %-22s %s\n' "$1" "$2" "$3"; }

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

lookup_ok='unknown'
dig_output=''
if [ -n "$name" ]; then
  printf '\n===== LOOKUP: %s =====\n' "$name"
  if command -v getent >/dev/null 2>&1; then
    printf '\n-- getent ahosts --\n'
    if getent ahosts "$name" 2>&1; then
      lookup_ok='yes'
    else
      lookup_ok='no'
    fi
  fi
  if command -v dig >/dev/null 2>&1; then
    printf '\n-- dig A/AAAA --\n'
    dig_output="$(dig "$name" A +noall +answer +comments 2>&1 || true)"
    printf '%s\n' "$dig_output"
    dig "$name" AAAA +noall +answer +comments 2>&1 || true
    printf '\n-- dig trace summary --\n'
    dig "$name" +trace +nodnssec 2>&1 | tail -n 30 || true
  elif command -v nslookup >/dev/null 2>&1; then
    nslookup "$name" 2>&1 || true
  else
    echo 'Neither dig nor nslookup is available.'
  fi
fi

printf '\n===== SUMMARY =====\n'
nameserver_count=0
if [ -r /etc/resolv.conf ]; then
  nameserver_count="$(awk '$1 == "nameserver" {count++} END {print count+0}' /etc/resolv.conf 2>/dev/null || printf 0)"
fi
if [ "$nameserver_count" -gt 0 ]; then
  summary_item OK 'resolver config' "$nameserver_count nameserver entry/entries in /etc/resolv.conf"
else
  summary_item WARN 'resolver config' 'no nameserver entries found in /etc/resolv.conf'
fi

if [ -n "$name" ]; then
  case "$lookup_ok" in
    yes) summary_item OK 'system resolver' "$name resolved through getent" ;;
    no) summary_item WARN 'system resolver' "$name did not resolve through getent" ;;
    *) summary_item INFO 'system resolver' 'getent unavailable; see resolver-tool output above' ;;
  esac

  if [ -n "$dig_output" ]; then
    if printf '%s\n' "$dig_output" | grep -qi 'no servers could be reached'; then
      summary_item WARN 'DNS transport' 'configured resolver(s) did not answer dig'
    elif printf '%s\n' "$dig_output" | grep -q 'status: SERVFAIL'; then
      summary_item WARN 'DNS response' 'SERVFAIL returned'
    elif printf '%s\n' "$dig_output" | grep -q 'status: NXDOMAIN'; then
      summary_item WARN 'DNS response' 'NXDOMAIN returned'
    elif printf '%s\n' "$dig_output" | grep -q 'status: NOERROR'; then
      summary_item OK 'DNS response' 'NOERROR returned for A query'
    fi
  fi
fi

if [ "$nameserver_count" -eq 0 ] || [ "$lookup_ok" = 'no' ]; then
  printf '\nSuggested next checks:\n'
  printf '  ror find --type runbook dns\n'
  printf '  ror collect network\n'
fi
