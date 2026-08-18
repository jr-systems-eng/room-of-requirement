#!/usr/bin/env bash

ror_workflow_index_file() { printf '%s\n' "$ROR_HOME/config/workflows/index.tsv"; }

ror_workflow_rows() {
  local name aliases mode status description script
  while IFS='|' read -r name aliases mode status description script; do
    case "$name" in ''|'#'*) continue ;; esac
    printf '%s|%s|%s|%s|%s|%s\n' "$name" "$aliases" "$mode" "$status" "$description" "$script"
  done < "$(ror_workflow_index_file)"
}

ror_workflow_names() {
  local name aliases mode status description script
  while IFS='|' read -r name aliases mode status description script; do
    printf '%s\n' "$name"
  done < <(ror_workflow_rows)
}

ror_workflow_resolve() {
  local requested="${1,,}" name aliases mode status description script alias old_ifs
  while IFS='|' read -r name aliases mode status description script; do
    if [ "$requested" = "$name" ]; then
      printf '%s\n' "$name"
      return 0
    fi
    if [ -n "$aliases" ]; then
      old_ifs="$IFS"
      IFS=','
      for alias in $aliases; do
        if [ "$requested" = "$alias" ]; then
          IFS="$old_ifs"
          printf '%s\n' "$name"
          return 0
        fi
      done
      IFS="$old_ifs"
    fi
  done < <(ror_workflow_rows)
  return 1
}

ror_workflow_record() {
  local requested="$1" name aliases mode status description script
  while IFS='|' read -r name aliases mode status description script; do
    [ "$name" = "$requested" ] || continue
    printf '%s|%s|%s|%s|%s|%s\n' "$name" "$aliases" "$mode" "$status" "$description" "$script"
    return 0
  done < <(ror_workflow_rows)
  return 1
}

ror_workflow_list() {
  local name aliases mode status description script
  printf 'Available workflows:\n'
  while IFS='|' read -r name aliases mode status description script; do
    printf '  %-26s %-12s %-12s %s\n' "$name" "$mode" "$status" "$description"
  done < <(ror_workflow_rows)
}

ror_workflow_run() {
  local requested="${1:-}" canonical record name aliases mode status description script
  [ -n "$requested" ] || {
    ror_workflow_list
    return 0
  }
  shift || true

  canonical="$(ror_workflow_resolve "$requested")" || return 2
  record="$(ror_workflow_record "$canonical")" || return 2
  IFS='|' read -r name aliases mode status description script <<< "$record"

  printf 'Workflow: %s\n' "$name"
  printf 'Status:   %s\n' "$status"
  printf 'Mode:     %s\n' "$mode"
  printf 'Purpose:  %s\n' "$description"
  printf '\n'

  [ -f "$ROR_HOME/$script" ] || {
    printf 'Workflow implementation missing: %s\n' "$script" >&2
    return 2
  }
  ROR_WORKFLOW_NAME="$name" ROR_WORKFLOW_MODE="$mode" ROR_WORKFLOW_STATUS="$status" \
    bash "$ROR_HOME/$script" "$@"
}
