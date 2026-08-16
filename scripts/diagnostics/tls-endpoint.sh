#!/usr/bin/env bash
set -u

target="${1:-}"
[ -n "$target" ] || { echo "Usage: $0 host[:port]" >&2; exit 2; }

host="$target"
port=443
case "$target" in
  *:*) host="${target%:*}"; port="${target##*:}" ;;
esac

printf '===== TLS ENDPOINT DIAGNOSTIC =====\n'
printf 'Target: %s:%s\n' "$host" "$port"
date 2>/dev/null || true

command -v openssl >/dev/null 2>&1 || { echo 'openssl is required' >&2; exit 1; }

tmp="${TMPDIR:-/tmp}/ror-tls-$$.pem"
trap 'rm -f "$tmp"' EXIT

printf '\n===== HANDSHAKE =====\n'
if command -v timeout >/dev/null 2>&1; then
  timeout 12 openssl s_client -connect "$host:$port" -servername "$host" -showcerts </dev/null 2>&1 | tee /tmp/ror-tls-output-$$.txt
  rc=${PIPESTATUS[0]}
else
  openssl s_client -connect "$host:$port" -servername "$host" -showcerts </dev/null 2>&1 | tee /tmp/ror-tls-output-$$.txt
  rc=${PIPESTATUS[0]}
fi
out="/tmp/ror-tls-output-$$.txt"
trap 'rm -f "$tmp" "$out"' EXIT

awk '/-----BEGIN CERTIFICATE-----/{flag=1} flag{print} /-----END CERTIFICATE-----/{exit}' "$out" > "$tmp"

printf '\n===== LEAF CERTIFICATE =====\n'
if [ -s "$tmp" ]; then
  openssl x509 -in "$tmp" -noout -subject -issuer -serial -dates -fingerprint -sha256 2>&1 || true
  printf '\n-- SANs --\n'
  openssl x509 -in "$tmp" -noout -ext subjectAltName 2>&1 || true
else
  echo 'No certificate could be extracted from the handshake.'
fi

printf '\n===== VERIFY RESULT =====\n'
grep -E 'Verify return code:|Verification error:|Protocol *:|Cipher *:' "$out" || true

exit "$rc"
