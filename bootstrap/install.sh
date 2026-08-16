#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BIN_DIR="${HOME}/.local/bin"
WRAPPER="$BIN_DIR/ror"

mkdir -p "$BIN_DIR"

cat > "$WRAPPER" <<EOF
#!/usr/bin/env bash
exec bash "$ROOT/bin/ror" "\$@"
EOF
chmod +x "$WRAPPER"

cat <<EOF
Room of Requirement installed.

Repository: $ROOT
Command:    $WRAPPER

If $BIN_DIR is not already in PATH, add this to your shell profile:
  export PATH="\$HOME/.local/bin:\$PATH"

Try:
  ror doctor
  ror find ssh
  ror cheat subnetting
EOF
