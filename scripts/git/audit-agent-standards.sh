#!/usr/bin/env bash
# Read-only local audit of AGENTS.md across direct child Git repositories.
set -euo pipefail

usage() {
  cat <<'HELP'
Usage: audit-agent-standards.sh [--root DIRECTORY] [--exclude repo1,repo2] [--strict]
Read-only scan of immediate Git repositories beneath DIRECTORY (default: current directory).
--exclude  Omit named directories from the scan (e.g. forks, empty repositories).
--strict   Return exit code 1 if any included repository lacks a tracked, clean
           AGENTS.md or has unresolved __TOKEN__ placeholders.
HELP
}

root="."
exclusions=","
strict=0

while (( $# > 0 )); do
  case "$1" in
    --root)
      if (( $# < 2 )); then echo "Missing directory after --root" >&2; exit 2; fi
      root="$2"
      shift 2
      ;;
    --exclude)
      if (( $# < 2 )); then echo "Missing list after --exclude" >&2; exit 2; fi
      exclusions=",$2,"
      shift 2
      ;;
    --strict)
      strict=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

command -v git >/dev/null 2>&1 || { echo "git is required" >&2; exit 2; }
[[ -d "$root" ]] || { echo "Directory not found: $root" >&2; exit 2; }
root="$(cd "$root" && pwd -P)"

total=0
clean=0
issues=0
printf 'REPOSITORY\tBRANCH\tAGENTS_STATUS\n'

for dir in "$root"/*/; do
  [[ -d "$dir" ]] || continue
  [[ -d "$dir/.git" || -f "$dir/.git" ]] || continue
  name="$(basename "$dir")"
  case "$exclusions" in
    *,"$name",*) continue ;;
  esac

  total=$((total + 1))
  branch_name="$(git -C "$dir" branch --show-current 2>/dev/null || true)"
  [[ -n "$branch_name" ]] || branch_name="detached"

  if [[ ! -f "$dir/AGENTS.md" ]]; then
    state="MISSING"
  elif git -C "$dir" ls-files --error-unmatch -- AGENTS.md >/dev/null 2>&1; then
    state="TRACKED"
    if [[ -n "$(git -C "$dir" status --porcelain -- AGENTS.md)" ]]; then
      state="MODIFIED"
    fi
  else
    state="LOCAL_ONLY"
  fi

  if [[ -f "$dir/AGENTS.md" ]] && grep -Eq '__[A-Z][A-Z0-9_]*__' "$dir/AGENTS.md"; then
    state="$state+PLACEHOLDERS"
  fi

  printf '%s\t%s\t%s\n' "$name" "$branch_name" "$state"
  if [[ "$state" == "TRACKED" ]]; then
    clean=$((clean + 1))
  else
    issues=$((issues + 1))
  fi
done

printf '\nRepositories: %d | tracked and clean: %d | need attention: %d\n' "$total" "$clean" "$issues"
if (( strict && issues > 0 )); then
  exit 1
fi
