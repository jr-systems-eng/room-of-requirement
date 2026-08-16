#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

export HOME="$TMP/home"
export ROR_STATE_HOME="$TMP/state"
mkdir -p "$HOME"
ROR=(bash "$ROOT/bin/ror")

assert_exact() {
  local file="$1" expected="$2"
  [ "$(cat "$file")" = "$expected" ] || {
    printf 'Unexpected content in %s\n' "$file" >&2
    exit 1
  }
}

printf 'original bashrc\n' > "$HOME/.bashrc"
printf 'original inputrc\n' > "$HOME/.inputrc"
printf 'original gitconfig\n' > "$HOME/.gitconfig"
printf 'original tmux\n' > "$HOME/.tmux.conf"

"${ROR[@]}" dotfiles status >/dev/null
"${ROR[@]}" dotfiles diff bash >/dev/null

"${ROR[@]}" dotfiles install bash >/dev/null
grep -Fqx '# >>> ROR managed bash >>>' "$HOME/.bashrc"
grep -Fqx '# >>> ROR managed inputrc >>>' "$HOME/.inputrc"
cmp -s "$ROOT/dotfiles/bash/bashrc" "$HOME/.config/ror/bashrc"
cmp -s "$ROOT/dotfiles/bash/inputrc" "$HOME/.config/ror/inputrc"
"${ROR[@]}" dotfiles restore latest >/dev/null
assert_exact "$HOME/.bashrc" 'original bashrc'
assert_exact "$HOME/.inputrc" 'original inputrc'
[ ! -e "$HOME/.config/ror/bashrc" ]
[ ! -e "$HOME/.config/ror/inputrc" ]

"${ROR[@]}" dotfiles install git >/dev/null
grep -Fqx '# >>> ROR managed git >>>' "$HOME/.gitconfig"
cmp -s "$ROOT/dotfiles/git/gitconfig" "$HOME/.config/ror/gitconfig"
cmp -s "$ROOT/dotfiles/git/gitignore_global" "$HOME/.config/ror/gitignore_global"
"${ROR[@]}" dotfiles restore latest >/dev/null
assert_exact "$HOME/.gitconfig" 'original gitconfig'
[ ! -e "$HOME/.config/ror/gitconfig" ]
[ ! -e "$HOME/.config/ror/gitignore_global" ]

"${ROR[@]}" dotfiles install tmux >/dev/null
grep -Fqx '# >>> ROR managed tmux >>>' "$HOME/.tmux.conf"
cmp -s "$ROOT/dotfiles/tmux/tmux.conf" "$HOME/.config/ror/tmux.conf"
"${ROR[@]}" dotfiles restore latest >/dev/null
assert_exact "$HOME/.tmux.conf" 'original tmux'
[ ! -e "$HOME/.config/ror/tmux.conf" ]

"${ROR[@]}" dotfiles backups | grep -q 'id='

printf 'Dotfile lifecycle smoke tests passed.\n'
