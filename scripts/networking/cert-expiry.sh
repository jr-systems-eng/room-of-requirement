#!/usr/bin/env bash
set -u

endpoint="${1:-}"
days="${2:-30}"

if [ -z "$endpoint" ] || ! [[ "$days" =~ ^[0-9]+$ ]]; then
  printf 'Usage: %s <host[:port]> [warning-days]\n' "${0##*/}" >&2
  exit 2
fi

host="$endpoint"
port='443'
if [[ "$endpoint" =~ ^\[([^]]+)\]:([0-9]+)$ ]]; then
  host="${BASH_REMATCH[1]}"
  port="${BASH_REMATCH[2]}"
elif [[ "$endpoint" =~ ^([^:]+):([0-9]+)$ ]]; then
  host="${BASH_REMATCH[1]}"
  port="${BASH_REMATCH[2]}"
fi

command -v openssl >/dev/null 2>&1 || { printf 'openssl is required\n' >&2; exit 1; }

tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT

if command -v timeout >/dev/null 2>&1; then
  timeout 10 openssl s_client -servername "$host" -connect "$host:$port" -showcerts </dev/null 2>/dev/null |
    awk '/-----BEGIN CERTIFICATE-----/{capture=1} capture{print} /-----END CERTIFICATE-----/{exit}' > "$tmp"
else
  openssl s_client -servername "$host" -connect "$host:$port" -showcerts </dev/null 2>/dev/null |
    awk '/-----BEGIN CERTIFICATE-----/{capture=1} capture{print} /-----END CERTIFICATE-----/{exit}' > "$tmp"
fi

if ! grep -q 'BEGIN CERTIFICATE' "$tmp"; then
  printf 'No leaf certificate received from %s:%s\n' "$host" "$port" >&2
  exit 1
fi

printf 'Endpoint: %s:%s\n' "$host" "$port"
openssl x509 -in "$tmp" -noout -subject -issuer -dates -fingerprint -sha256

seconds=$((days * 86400))
if openssl x509 -in "$tmp" -checkend "$seconds" -noout >/dev/null 2>&1; then
  printf 'Status: certificate remains valid for more than %s day(s).\n' "$days"
  exit 0
fi

if openssl x509 -in "$tmp" -checkend 0 -noout >/dev/null 2>&1; then
  printf 'Status: WARNING - certificate expires within %s day(s).\n' "$days"
else
  printf 'Status: CRITICAL - certificate is expired.\n'
fi
exit 2
