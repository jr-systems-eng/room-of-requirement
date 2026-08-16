#!/usr/bin/env bash
set -u

target="${1:-}"
[ -n "$target" ] || { echo "Usage: $0 host[:port]" >&2; exit 2; }

host="$target"
port=443
case "$target" in
  *:*) host="${target%:*}"; port="${target##*:}" ;;
esac

summary_item() { printf '  [%-4s] %-22s %s\n' "$1" "$2" "$3"; }

printf '===== TLS ENDPOINT DIAGNOSTIC =====\n'
printf 'Target: %s:%s\n' "$host" "$port"
date 2>/dev/null || true

command -v openssl >/dev/null 2>&1 || { echo 'openssl is required' >&2; exit 1; }

tmp="${TMPDIR:-/tmp}/ror-tls-$$.pem"
out="${TMPDIR:-/tmp}/ror-tls-output-$$.txt"
trap 'rm -f "$tmp" "$out"' EXIT

printf '\n===== HANDSHAKE =====\n'
if command -v timeout >/dev/null 2>&1; then
  timeout 12 openssl s_client -connect "$host:$port" -servername "$host" -showcerts </dev/null 2>&1 | tee "$out"
  rc=${PIPESTATUS[0]}
else
  openssl s_client -connect "$host:$port" -servername "$host" -showcerts </dev/null 2>&1 | tee "$out"
  rc=${PIPESTATUS[0]}
fi

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

printf '\n===== SUMMARY =====\n'
if [ -s "$tmp" ]; then
  summary_item OK 'certificate' 'leaf certificate received'
else
  summary_item WARN 'certificate' 'no leaf certificate received'
fi

verify_line="$(grep -E 'Verify return code:' "$out" | tail -n 1 || true)"
if printf '%s' "$verify_line" | grep -qE 'Verify return code: *0 \(ok\)'; then
  summary_item OK 'chain verification' 'OpenSSL reported verify code 0'
elif [ -n "$verify_line" ]; then
  summary_item WARN 'chain verification' "${verify_line#*: }"
elif grep -qi 'Verification error:' "$out"; then
  summary_item WARN 'chain verification' "$(grep -i 'Verification error:' "$out" | tail -n 1)"
else
  summary_item INFO 'chain verification' 'no verify result found in handshake output'
fi

if [ -s "$tmp" ]; then
  if ! openssl x509 -in "$tmp" -noout -checkend 0 >/dev/null 2>&1; then
    summary_item WARN 'certificate expiry' 'certificate is expired'
  elif ! openssl x509 -in "$tmp" -noout -checkend 604800 >/dev/null 2>&1; then
    summary_item WARN 'certificate expiry' 'expires within 7 days'
  elif ! openssl x509 -in "$tmp" -noout -checkend 2592000 >/dev/null 2>&1; then
    summary_item WARN 'certificate expiry' 'expires within 30 days'
  else
    summary_item OK 'certificate expiry' 'valid for more than 30 days'
  fi

  if openssl x509 -help 2>&1 | grep -q -- '-checkhost'; then
    if openssl x509 -in "$tmp" -noout -checkhost "$host" >/dev/null 2>&1; then
      summary_item OK 'hostname' "$host matches certificate names"
    else
      summary_item WARN 'hostname' "$host does not match certificate names"
    fi
  fi
fi

if [ "$rc" -ne 0 ]; then
  summary_item WARN 'handshake command' "openssl s_client exited $rc"
fi

if [ ! -s "$tmp" ] || ! printf '%s' "$verify_line" | grep -qE 'Verify return code: *0 \(ok\)'; then
  printf '\nSuggested next checks:\n'
  printf '  ror find --type runbook certificate\n'
  printf '  ror collect tls %s\n' "$target"
fi

exit "$rc"
