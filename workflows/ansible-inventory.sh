#!/usr/bin/env bash
set -u

SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
. "$SELF_DIR/common.sh"

usage() {
  cat <<'EOF'
Usage:
  ror workflow ansible-inventory --inventory PATH [--host HOST]

This workflow is read-only. It validates inventory parsing, prints the graph, and optionally renders host variables. It does not connect to managed hosts.
EOF
}

inventory='' host=''
while [ "$#" -gt 0 ]; do
  case "$1" in
    --inventory|-i) inventory="${2:-}"; shift 2 ;;
    --host) host="${2:-}"; shift 2 ;;
    --help|-h) usage; exit 0 ;;
    *) printf 'Unknown option: %s\n' "$1" >&2; usage >&2; exit 2 ;;
  esac
done
[ -n "$inventory" ] || { usage >&2; exit 2; }

workflow_section 'Preflight'
if workflow_have ansible-inventory; then
  workflow_item OK 'ansible-inventory' "$(ansible-inventory --version 2>/dev/null | head -1 || printf available)"
else
  workflow_item FAIL 'ansible-inventory' 'not found; install/activate Ansible first'
  exit 1
fi
if [ -r "$inventory" ]; then
  workflow_item OK 'inventory file' "$inventory"
else
  workflow_item FAIL 'inventory file' 'not readable'
  exit 1
fi

workflow_section 'Validation'
if ansible-inventory -i "$inventory" --list >/dev/null; then
  workflow_item OK 'inventory parse' 'successful'
else
  workflow_item FAIL 'inventory parse' 'ansible-inventory rejected the inventory'
  exit 1
fi

workflow_section 'Inventory graph'
ansible-inventory -i "$inventory" --graph

if [ -n "$host" ]; then
  workflow_section "Host variables: $host"
  ansible-inventory -i "$inventory" --host "$host"
fi

workflow_section 'Result'
printf 'Changes: NONE. No managed-host connection was attempted.\n'
