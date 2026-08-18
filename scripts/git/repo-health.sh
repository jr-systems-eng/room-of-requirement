#!/usr/bin/env bash
set -u

repo="${1:-.}"
command -v git >/dev/null 2>&1 || { printf 'git is required\n' >&2; exit 1; }

git -C "$repo" rev-parse --is-inside-work-tree >/dev/null 2>&1 || {
  printf 'Not a Git worktree: %s\n' "$repo" >&2
  exit 2
}

top="$(git -C "$repo" rev-parse --show-toplevel 2>/dev/null)"
branch="$(git -C "$repo" branch --show-current 2>/dev/null || true)"
head="$(git -C "$repo" rev-parse --short HEAD 2>/dev/null || true)"
upstream="$(git -C "$repo" rev-parse --abbrev-ref --symbolic-full-name '@{upstream}' 2>/dev/null || true)"
status="$(git -C "$repo" status --porcelain=v1 2>/dev/null || true)"
changes="$(printf '%s\n' "$status" | sed '/^[[:space:]]*$/d' | wc -l | tr -d ' ')"

printf 'Repository: %s\n' "$top"
printf 'Branch:     %s\n' "${branch:-detached HEAD}"
printf 'Commit:     %s\n' "$head"
printf 'Upstream:   %s\n' "${upstream:-none}"
printf 'Changes:    %s\n' "$changes"

remote_names="$(git -C "$repo" remote 2>/dev/null || true)"
printf 'Remotes:    %s\n' "${remote_names//$'\n'/, }"

if [ -n "$upstream" ]; then
  counts="$(git -C "$repo" rev-list --left-right --count HEAD..."$upstream" 2>/dev/null || true)"
  if [ -n "$counts" ]; then
    ahead="$(printf '%s\n' "$counts" | awk '{print $1}')"
    behind="$(printf '%s\n' "$counts" | awk '{print $2}')"
    printf 'Ahead:      %s\n' "$ahead"
    printf 'Behind:     %s\n' "$behind"
  fi
fi

printf '\n===== WORKTREE =====\n'
if [ -n "$status" ]; then
  printf '%s\n' "$status"
else
  printf 'clean\n'
fi

printf '\n===== RECENT COMMIT =====\n'
git -C "$repo" log -1 --date=iso --format='%h %ad %an%n%s' 2>/dev/null || true

printf '\nNote: remote URLs are intentionally not printed because they can contain embedded credentials/tokens.\n'
