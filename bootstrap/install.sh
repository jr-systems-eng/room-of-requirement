#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BIN_DIR="${HOME}/.local/bin"
WRAPPER="$BIN_DIR/ror"
PACKAGE_PROFILE=''
DOTFILE_GROUPS=()
RUN_DOCTOR='yes'

usage() {
  cat <<'EOF'
Usage: bash bootstrap/install.sh [options]

Options:
  --profile PROFILE       Explicitly install an ROR package profile.
  --dotfiles GROUP        Explicitly install a dotfile group. Repeatable.
  --no-doctor             Skip the final read-only `ror doctor` check.
  -h, --help              Show this help.

Examples:
  bash bootstrap/install.sh
  bash bootstrap/install.sh --profile minimal
  bash bootstrap/install.sh --profile linux-admin --dotfiles bash --dotfiles git
  bash bootstrap/install.sh --dotfiles all
EOF
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --profile)
      [ "$#" -ge 2 ] || { printf 'Missing value for --profile\n' >&2; exit 2; }
      PACKAGE_PROFILE="$2"
      shift 2
      ;;
    --dotfiles)
      [ "$#" -ge 2 ] || { printf 'Missing value for --dotfiles\n' >&2; exit 2; }
      DOTFILE_GROUPS+=("$2")
      shift 2
      ;;
    --no-doctor)
      RUN_DOCTOR='no'
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      printf 'Unknown option: %s\n' "$1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

mkdir -p "$BIN_DIR"

cat > "$WRAPPER" <<EOF
#!/usr/bin/env bash
exec bash "$ROOT/bin/ror" "\$@"
EOF
chmod +x "$WRAPPER"

printf 'Room of Requirement command installed.\n\n'
printf 'Repository: %s\n' "$ROOT"
printf 'Command:    %s\n' "$WRAPPER"

if [ -n "$PACKAGE_PROFILE" ]; then
  printf '\nInstalling requested package profile: %s\n' "$PACKAGE_PROFILE"
  bash "$ROOT/bin/ror" pkg install "$PACKAGE_PROFILE"
fi

if [ "${#DOTFILE_GROUPS[@]}" -gt 0 ]; then
  for group in "${DOTFILE_GROUPS[@]}"; do
    printf '\nInstalling requested dotfile group: %s\n' "$group"
    bash "$ROOT/bin/ror" dotfiles install "$group"
  done
fi

if [ "$RUN_DOCTOR" = 'yes' ]; then
  printf '\nRunning read-only environment check...\n'
  bash "$ROOT/bin/ror" doctor
fi

cat <<EOF

If $BIN_DIR is not already in PATH, add this to your shell profile:
  export PATH="\$HOME/.local/bin:\$PATH"

Useful next commands:
  ror doctor --install-suggestions
  ror pkg list
  ror dotfiles status
  ror dotfiles diff all
EOF
