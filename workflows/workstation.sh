#!/usr/bin/env bash
set -u

SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROR_HOME="$(cd "$SELF_DIR/.." && pwd)"
# shellcheck source=common.sh
. "$SELF_DIR/common.sh"

usage() {
  cat <<'EOF'
Usage:
  ror workflow workstation [--profile PROFILE] [--dotfiles GROUPS] [--apply]

Defaults:
  --profile linux-admin
  --dotfiles bash,git,tmux

GROUPS is a comma-separated list or `none`.
Default invocation shows package suggestions and dotfile diffs only.
EOF
}

profile='linux-admin' groups='bash,git,tmux' apply='no'
while [ "$#" -gt 0 ]; do
  case "$1" in
    --profile) profile="${2:-}"; shift 2 ;;
    --dotfiles) groups="${2:-}"; shift 2 ;;
    --apply) apply='yes'; shift ;;
    --help|-h) usage; exit 0 ;;
    *) printf 'Unknown option: %s\n' "$1" >&2; usage >&2; exit 2 ;;
  esac
done

workflow_section 'Preflight / package plan'
bash "$ROR_HOME/bin/ror" pkg suggest "$profile"

workflow_section 'Dotfile plan'
invalid=0
if [ "$groups" = 'none' ]; then
  printf '  No dotfile groups requested.\n'
else
  old_ifs="$IFS"; IFS=','
  for group in $groups; do
    IFS="$old_ifs"
    if bash "$ROR_HOME/bin/ror" dotfiles diff "$group"; then
      :
    else
      workflow_item FAIL 'dotfile group' "$group could not be inspected"
      invalid=1
    fi
    IFS=','
  done
  IFS="$old_ifs"
fi

workflow_section 'Plan'
printf '  1. Install missing package-managed items for profile/request: %s\n' "$profile"
printf '  2. Leave vendor-specific/external tools as explicit follow-up work.\n'
if [ "$groups" = 'none' ]; then
  printf '  3. Do not change managed dotfiles.\n'
else
  printf '  3. Install managed dotfile groups: %s\n' "$groups"
  printf '  4. Each dotfile install creates a timestamped rollback snapshot before modifying host files.\n'
fi

if [ "$apply" != 'yes' ]; then
  printf '\n'
  workflow_plan_only_banner
  [ "$invalid" -eq 0 ] || printf 'One or more requested dotfile groups must be corrected before apply.\n'
  exit 0
fi
[ "$invalid" -eq 0 ] || { printf 'Refusing apply because a dotfile group failed validation.\n' >&2; exit 1; }

workflow_section 'Apply packages'
bash "$ROR_HOME/bin/ror" pkg install "$profile"

if [ "$groups" != 'none' ]; then
  workflow_section 'Apply dotfiles'
  old_ifs="$IFS"; IFS=','
  for group in $groups; do
    IFS="$old_ifs"
    bash "$ROR_HOME/bin/ror" dotfiles install "$group"
    IFS=','
  done
  IFS="$old_ifs"
fi

workflow_section 'Validation'
bash "$ROR_HOME/bin/ror" pkg suggest "$profile"
bash "$ROR_HOME/bin/ror" dotfiles status

workflow_section 'Rollback guidance'
printf '  Package installation is not automatically rolled back because package-manager removal can affect dependencies.\n'
printf '  Dotfile install output above contains the exact backup IDs; use `ror dotfiles restore <backup-id>` for the groups you applied.\n'
