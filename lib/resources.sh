#!/usr/bin/env bash

# Deterministic relationship layer used by `ror need`.
# Topic metadata lives in config/room so the content graph can grow without
# turning this implementation into a large hand-maintained case statement.

ror_room_topics_file() { printf '%s\n' "$ROR_HOME/config/room/topics.tsv"; }
ror_room_actions_file() { printf '%s\n' "$ROR_HOME/config/room/actions.tsv"; }
ror_room_resources_file() { printf '%s\n' "$ROR_HOME/config/room/resources.tsv"; }

ror_need_topics() {
  local topic aliases description related
  while IFS='|' read -r topic aliases description related; do
    case "$topic" in ''|'#'*) continue ;; esac
    printf '%s\n' "$topic"
  done < "$(ror_room_topics_file)"
}

ror_need_canonical_topic() {
  local requested="${1,,}" topic aliases description related alias
  case "$requested" in
    list|topics) printf 'list\n'; return 0 ;;
  esac

  while IFS='|' read -r topic aliases description related; do
    case "$topic" in ''|'#'*) continue ;; esac
    if [ "$requested" = "$topic" ]; then
      printf '%s\n' "$topic"
      return 0
    fi
    if [ -n "$aliases" ]; then
      local old_ifs="$IFS"
      IFS=','
      for alias in $aliases; do
        if [ "$requested" = "$alias" ]; then
          IFS="$old_ifs"
          printf '%s\n' "$topic"
          return 0
        fi
      done
      IFS="$old_ifs"
    fi
  done < "$(ror_room_topics_file)"
  return 1
}

ror_need_description() {
  local requested="$1" topic aliases description related
  while IFS='|' read -r topic aliases description related; do
    case "$topic" in ''|'#'*) continue ;; esac
    [ "$topic" = "$requested" ] || continue
    printf '%s\n' "$description"
    return 0
  done < "$(ror_room_topics_file)"
  return 1
}

ror_need_related() {
  local requested="$1" topic aliases description related
  while IFS='|' read -r topic aliases description related; do
    case "$topic" in ''|'#'*) continue ;; esac
    [ "$topic" = "$requested" ] || continue
    [ -n "$related" ] || return 0
    printf '%s\n' "$related" | tr ',' '\n'
    return 0
  done < "$(ror_room_topics_file)"
}

ror_need_commands() {
  local requested="$1" topic command
  while IFS='|' read -r topic command; do
    case "$topic" in ''|'#'*) continue ;; esac
    [ "$topic" = "$requested" ] || continue
    printf '%s\n' "$command"
  done < "$(ror_room_actions_file)"
}

# Output rows are TYPE|PATH|NOTE. Paths are relative to ROR_HOME.
ror_need_resources() {
  local requested="$1" topic type path note
  while IFS='|' read -r topic type path note; do
    case "$topic" in ''|'#'*) continue ;; esac
    [ "$topic" = "$requested" ] || continue
    printf '%s|%s|%s\n' "$type" "$path" "$note"
  done < "$(ror_room_resources_file)"
}

ror_need_print() {
  local requested="${1:-}" topic type path note current_type=''
  local actions first_action other_actions related description

  [ -n "$requested" ] || {
    printf 'Curated topics:\n'
    ror_need_topics | sed 's/^/  /'
    return 0
  }

  topic="$(ror_need_canonical_topic "$requested")" || return 2
  if [ "$topic" = 'list' ]; then
    printf 'Curated topics:\n'
    ror_need_topics | sed 's/^/  /'
    return 0
  fi

  description="$(ror_need_description "$topic")"
  actions="$(ror_need_commands "$topic")"
  first_action="$(printf '%s\n' "$actions" | sed -n '1p')"
  other_actions="$(printf '%s\n' "$actions" | sed -n '2,$p')"

  printf 'Room of Requirement: %s\n' "$topic"
  printf 'Purpose: %s\n' "$description"

  if [ -n "$first_action" ]; then
    printf '\nStart here:\n'
    printf '  %s\n' "$first_action"
  fi

  if [ -n "$other_actions" ]; then
    printf '\nNext actions:\n'
    printf '%s\n' "$other_actions" | sed 's/^/  /'
  fi

  printf '\nResources:\n'
  while IFS='|' read -r type path note; do
    [ -n "$path" ] || continue
    [ -e "$ROR_HOME/$path" ] || continue
    if [ "$type" != "$current_type" ]; then
      printf '  %s\n' "$type"
      current_type="$type"
    fi
    printf '    %-52s %s\n' "$path" "$note"
  done < <(ror_need_resources "$topic")

  related="$(ror_need_related "$topic")"
  if [ -n "$related" ]; then
    printf '\nRelated rooms:\n'
    while IFS= read -r related_topic; do
      [ -n "$related_topic" ] || continue
      printf '  %-16s %s\n' "$related_topic" "$(ror_need_description "$related_topic")"
    done <<< "$related"
  fi
}
