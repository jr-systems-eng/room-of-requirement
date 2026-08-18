#!/usr/bin/env bash
set -u

SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
. "$SELF_DIR/common.sh"

usage() {
  cat <<'EOF'
Usage:
  ror workflow certificate-deploy-prep --cert CERT.pem --key KEY.pem [options]

Options:
  --chain CHAIN.pem   Optional intermediate/chain file for openssl verify
  --target PATH       Intended deployment target; inspected only, never replaced
  --days N            Expiry warning window (default: 30)
  --help

This is a preparation-only workflow. It never deploys or replaces certificate files.
EOF
}

cert='' key='' chain='' target='' days=30
while [ "$#" -gt 0 ]; do
  case "$1" in
    --cert) cert="${2:-}"; shift 2 ;;
    --key) key="${2:-}"; shift 2 ;;
    --chain) chain="${2:-}"; shift 2 ;;
    --target) target="${2:-}"; shift 2 ;;
    --days) days="${2:-}"; shift 2 ;;
    --apply) printf 'certificate-deploy-prep is preparation-only and intentionally has no --apply mode.\n' >&2; exit 2 ;;
    --help|-h) usage; exit 0 ;;
    *) printf 'Unknown option: %s\n' "$1" >&2; usage >&2; exit 2 ;;
  esac
done
[ -n "$cert" ] && [ -n "$key" ] || { usage >&2; exit 2; }
[[ "$days" =~ ^[0-9]+$ ]] || { printf '--days must be a non-negative integer.\n' >&2; exit 2; }

workflow_section 'Preflight'
workflow_have openssl || { workflow_item FAIL 'openssl' 'required'; exit 1; }
workflow_item OK 'openssl' "$(openssl version 2>/dev/null || printf available)"
for file in "$cert" "$key"; do
  if [ -r "$file" ]; then workflow_item OK 'readable file' "$file"; else workflow_item FAIL 'readable file' "$file"; exit 1; fi
done
if [ -n "$chain" ]; then
  [ -r "$chain" ] || { workflow_item FAIL 'chain file' "$chain is not readable"; exit 1; }
  workflow_item OK 'chain file' "$chain"
fi

workflow_section 'Certificate'
if openssl x509 -in "$cert" -noout -subject -issuer -serial -dates -fingerprint -sha256; then
  workflow_item OK 'certificate parse' 'successful'
else
  workflow_item FAIL 'certificate parse' 'openssl x509 could not parse the file'
  exit 1
fi

seconds=$((days * 86400))
if openssl x509 -in "$cert" -noout -checkend "$seconds" >/dev/null 2>&1; then
  workflow_item OK 'expiry window' "certificate remains valid beyond ${days} days"
else
  workflow_item WARN 'expiry window' "certificate expires within ${days} days or is already expired"
fi

workflow_section 'Certificate/key match'
cert_pub="$(openssl x509 -in "$cert" -pubkey -noout 2>/dev/null | openssl pkey -pubin -outform DER 2>/dev/null | openssl dgst -sha256 2>/dev/null || true)"
key_pub="$(openssl pkey -in "$key" -passin pass: -pubout -outform DER 2>/dev/null | openssl dgst -sha256 2>/dev/null || true)"
if [ -z "$key_pub" ]; then
  workflow_item WARN 'private key parse' 'key may be encrypted or unreadable; no passphrase prompt was attempted'
elif [ -n "$cert_pub" ] && [ "$cert_pub" = "$key_pub" ]; then
  workflow_item OK 'public-key match' 'certificate and private key match'
else
  workflow_item FAIL 'public-key match' 'certificate and private key do not match'
  exit 1
fi

if [ -n "$chain" ]; then
  workflow_section 'Chain verification'
  if openssl verify -untrusted "$chain" "$cert"; then
    workflow_item OK 'openssl verify' 'leaf verified using supplied chain material'
  else
    workflow_item WARN 'openssl verify' 'supplied chain did not verify the leaf with the local trust context'
  fi
fi

workflow_section 'Deployment preparation'
if [ -n "$target" ]; then
  printf '  Intended target: %s\n' "$target"
  if [ -e "$target" ]; then
    printf '  Existing target metadata:\n'
    ls -l "$target" 2>/dev/null | sed 's/^/    /' || true
    if workflow_have sha256sum; then
      sha256sum "$target" 2>/dev/null | sed 's/^/    /' || true
    fi
    printf '  Planned backup naming: %s.ror-YYYYMMDD-HHMMSS.bak\n' "$target"
  else
    printf '  Existing target: absent\n'
  fi
else
  printf '  No deployment target supplied; certificate material inspection only.\n'
fi
printf '  Verify service-specific ownership, permissions, path/alias expectations, and reload/restart procedure before deployment.\n'

workflow_section 'Result'
printf 'Changes: NONE. This workflow intentionally stops before certificate deployment.\n'
