#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BIN_DIR="${HOME}/.local/bin"

mkdir -p "$BIN_DIR"
chmod +x "$ROOT/bin/ror"
find "$ROOT/scripts" -type f -name '*.sh' -exec chmod +x {} + 2>/dev/null || true
ln -sfn "$ROOT/bin/ror" "$BIN_DIR/ror"

cat <<EOF
Room of Requirement installed.

Repository: $ROOT
Command:    $BIN_DIR/ror

If $BIN_DIR is not already in PATH, add this to your shell profile:
  export PATH="\$HOME/.local/bin:\$PATH"

Try:
  ror doctor
  ror find ssh
  ror cheat subnetting
EOF
