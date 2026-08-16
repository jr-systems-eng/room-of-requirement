#!/usr/bin/env bash

# Managed fragments intentionally use one predictable location across Unix,
# WSL, Git Bash, and PowerShell. Machine-specific overrides live below
# ~/.config/ror/local/ and are never written by ROR.
ror_dotfiles_config_home() {
  printf '%s/.config/ror\n' "$HOME"
}

ror_dotfiles_state_home() {
  if [ -n "${ROR_STATE_HOME:-}" ]; then
    printf '%s\n' "$ROR_STATE_HOME"
  elif [ -n "${XDG_STATE_HOME:-}" ]; then
    printf '%s/ror\n' "$XDG_STATE_HOME"
  else
    printf '%s/.local/state/ror\n' "$HOME"
  fi
}

ror_dotfiles_is_windows_bash() {
  case "$(uname -s 2>/dev/null || true)" in
    MINGW*|MSYS*|CYGWIN*) return 0 ;;
    *) return 1 ;;
  esac
}

ror_dotfiles_groups() {
  printf '%s\n' bash git tmux
  if ror_dotfiles_is_windows_bash || command -v pwsh >/dev/null 2>&1; then
    printf '%s\n' powershell
  fi
}

ror_dotfiles_source_files() {
  local group="$1"
  case "$group" in
    bash)
      printf '%s\n' 'dotfiles/bash/bashrc|bashrc'
      printf '%s\n' 'dotfiles/bash/inputrc|inputrc'
      ;;
    git)
      printf '%s\n' 'dotfiles/git/gitconfig|gitconfig'
      printf '%s\n' 'dotfiles/git/gitignore_global|gitignore_global'
      ;;
    tmux)
      printf '%s\n' 'dotfiles/tmux/tmux.conf|tmux.conf'
      ;;
    powershell)
      printf '%s\n' 'dotfiles/windows/powershell_profile.ps1|powershell_profile.ps1'
      ;;
    *) return 1 ;;
  esac
}

ror_dotfiles_powershell_profile() {
  local win_path=''
  if ror_dotfiles_is_windows_bash; then
    if command -v pwsh.exe >/dev/null 2>&1; then
      win_path="$(pwsh.exe -NoProfile -Command '$PROFILE.CurrentUserCurrentHost' 2>/dev/null | tr -d '\r' | tail -n 1)"
    elif command -v powershell.exe >/dev/null 2>&1; then
      win_path="$(powershell.exe -NoProfile -Command '$PROFILE.CurrentUserCurrentHost' 2>/dev/null | tr -d '\r' | tail -n 1)"
    fi
    if [ -n "$win_path" ] && command -v cygpath >/dev/null 2>&1; then
      cygpath -u "$win_path"
      return
    fi
  elif command -v pwsh >/dev/null 2>&1; then
    pwsh -NoProfile -Command '$PROFILE.CurrentUserCurrentHost' 2>/dev/null | tail -n 1
    return
  fi
  return 1
}

ror_dotfiles_integration_target() {
  local group="$1"
  case "$group" in
    bash) printf '%s/.bashrc\n' "$HOME" ;;
    git) printf '%s/.gitconfig\n' "$HOME" ;;
    tmux) printf '%s/.tmux.conf\n' "$HOME" ;;
    powershell) ror_dotfiles_powershell_profile ;;
    *) return 1 ;;
  esac
}

ror_dotfiles_marker_begin() {
  printf '# >>> ROR managed %s >>>\n' "$1"
}

ror_dotfiles_marker_end() {
  printf '# <<< ROR managed %s <<<\n' "$1"
}

ror_dotfiles_block() {
  local group="$1" config_home="$2"
  case "$group" in
    bash)
      cat <<EOF
# >>> ROR managed bash >>>
if [ -r "$config_home/bashrc" ]; then
  . "$config_home/bashrc"
fi
# <<< ROR managed bash <<<
EOF
      ;;
    git)
      cat <<EOF
# >>> ROR managed git >>>
[include]
    path = $config_home/gitconfig
# <<< ROR managed git <<<
EOF
      ;;
    tmux)
      cat <<EOF
# >>> ROR managed tmux >>>
source-file "$config_home/tmux.conf"
# <<< ROR managed tmux <<<
EOF
      ;;
    powershell)
      cat <<'EOF'
# >>> ROR managed powershell >>>
$RorManagedProfile = Join-Path $HOME '.config\ror\powershell_profile.ps1'
if (Test-Path $RorManagedProfile) { . $RorManagedProfile }
# <<< ROR managed powershell <<<
EOF
      ;;
    *) return 1 ;;
  esac
}

ror_dotfiles_inputrc_target() {
  printf '%s/.inputrc\n' "$HOME"
}

ror_dotfiles_inputrc_block() {
  local config_home="$1"
  cat <<EOF
# >>> ROR managed inputrc >>>
\$include $config_home/inputrc
# <<< ROR managed inputrc <<<
EOF
}

ror_dotfiles_has_block() {
  local file="$1" begin="$2"
  [ -f "$file" ] && grep -Fqx -- "$begin" "$file" 2>/dev/null
}

ror_dotfiles_replace_block() {
  local file="$1" begin="$2" end="$3" content="$4" tmp
  mkdir -p "$(dirname "$file")"
  tmp="${file}.ror-tmp-$$"

  if [ -f "$file" ]; then
    awk -v begin="$begin" -v end="$end" '
      $0 == begin { skip=1; next }
      $0 == end   { skip=0; next }
      !skip       { print }
    ' "$file" > "$tmp"
  else
    : > "$tmp"
  fi

  if [ -s "$tmp" ]; then
    printf '\n' >> "$tmp"
  fi
  printf '%s\n' "$content" >> "$tmp"
  mv "$tmp" "$file"
}

ror_dotfiles_backup_once() {
  local backup_dir="$1" target="$2" manifest="$backup_dir/manifest.tsv" index backup existed
  mkdir -p "$backup_dir/files"
  touch "$manifest"

  if awk -F '\t' -v target="$target" '$1 == target { found=1 } END { exit !found }' "$manifest" 2>/dev/null; then
    return 0
  fi

  index="$(awk 'END { print NR + 1 }' "$manifest")"
  backup="$backup_dir/files/$(printf '%03d' "$index")"
  if [ -e "$target" ]; then
    cp -p "$target" "$backup"
    existed=1
  else
    : > "$backup"
    existed=0
  fi
  printf '%s\t%s\t%s\n' "$target" "$backup" "$existed" >> "$manifest"
}

ror_dotfiles_new_backup() {
  local state_home backup_root id backup_dir
  state_home="$(ror_dotfiles_state_home)"
  backup_root="$state_home/dotfiles-backups"
  mkdir -p "$backup_root"
  id="$(date +%Y%m%d-%H%M%S)-$$"
  backup_dir="$backup_root/$id"
  mkdir -p "$backup_dir"
  {
    printf 'id=%s\n' "$id"
    printf 'created=%s\n' "$(date -Is 2>/dev/null || date)"
    printf 'host=%s\n' "$(hostname 2>/dev/null || printf unknown)"
  } > "$backup_dir/meta"
  printf '%s\n' "$backup_dir"
}

ror_dotfiles_copy_managed() {
  local backup_dir="$1" group="$2" config_home source rel
  config_home="$(ror_dotfiles_config_home)"
  mkdir -p "$config_home"

  while IFS='|' read -r source rel; do
    [ -n "$source" ] || continue
    [ -f "$ROR_HOME/$source" ] || { printf 'Missing dotfile source: %s\n' "$source" >&2; return 1; }
    ror_dotfiles_backup_once "$backup_dir" "$config_home/$rel"
    cp "$ROR_HOME/$source" "$config_home/$rel"
  done < <(ror_dotfiles_source_files "$group")
}

ror_dotfiles_install_group() {
  local backup_dir="$1" group="$2" config_home target begin end block input_target input_block
  config_home="$(ror_dotfiles_config_home)"

  target="$(ror_dotfiles_integration_target "$group")" || {
    printf 'Unsupported dotfile group on this platform: %s\n' "$group" >&2
    return 2
  }

  ror_dotfiles_copy_managed "$backup_dir" "$group" || return 1

  begin="$(ror_dotfiles_marker_begin "$group")"
  end="$(ror_dotfiles_marker_end "$group")"
  block="$(ror_dotfiles_block "$group" "$config_home")"
  ror_dotfiles_backup_once "$backup_dir" "$target"
  ror_dotfiles_replace_block "$target" "$begin" "$end" "$block"

  if [ "$group" = 'bash' ]; then
    input_target="$(ror_dotfiles_inputrc_target)"
    input_block="$(ror_dotfiles_inputrc_block "$config_home")"
    ror_dotfiles_backup_once "$backup_dir" "$input_target"
    ror_dotfiles_replace_block "$input_target" '# >>> ROR managed inputrc >>>' '# <<< ROR managed inputrc <<<' "$input_block"
  fi
}

ror_dotfiles_group_status() {
  local group="$1" config_home target begin source rel state='current' integration='linked'
  config_home="$(ror_dotfiles_config_home)"

  while IFS='|' read -r source rel; do
    [ -n "$source" ] || continue
    if [ ! -f "$config_home/$rel" ]; then
      state='missing'
    elif ! cmp -s "$ROR_HOME/$source" "$config_home/$rel"; then
      state='drifted'
    fi
  done < <(ror_dotfiles_source_files "$group")

  target="$(ror_dotfiles_integration_target "$group" 2>/dev/null || true)"
  begin="$(ror_dotfiles_marker_begin "$group")"
  if [ -z "$target" ] || ! ror_dotfiles_has_block "$target" "$begin"; then
    integration='unlinked'
  fi

  if [ "$group" = 'bash' ] && ! ror_dotfiles_has_block "$(ror_dotfiles_inputrc_target)" '# >>> ROR managed inputrc >>>'; then
    integration='partial'
  fi

  printf '%-12s managed=%-8s integration=%s\n' "$group" "$state" "$integration"
}

ror_dotfiles_status() {
  local group
  printf 'Config home: %s\n' "$(ror_dotfiles_config_home)"
  printf 'State home:  %s\n\n' "$(ror_dotfiles_state_home)"
  while IFS= read -r group; do
    ror_dotfiles_group_status "$group"
  done < <(ror_dotfiles_groups)
}

ror_dotfiles_diff_group() {
  local group="$1" config_home source rel target begin
  config_home="$(ror_dotfiles_config_home)"
  printf '===== %s =====\n' "$group"

  while IFS='|' read -r source rel; do
    [ -n "$source" ] || continue
    printf '\n-- managed file: %s --\n' "$config_home/$rel"
    if [ -f "$config_home/$rel" ]; then
      diff -u "$config_home/$rel" "$ROR_HOME/$source" || true
    else
      printf 'would create from %s\n' "$source"
    fi
  done < <(ror_dotfiles_source_files "$group")

  target="$(ror_dotfiles_integration_target "$group" 2>/dev/null || true)"
  begin="$(ror_dotfiles_marker_begin "$group")"
  printf '\n-- integration: %s --\n' "${target:-unsupported}"
  if [ -n "$target" ] && ror_dotfiles_has_block "$target" "$begin"; then
    printf 'managed include/source block present\n'
  elif [ -n "$target" ]; then
    printf 'managed include/source block would be added\n'
  else
    printf 'group is not supported on this platform\n'
  fi
}

ror_dotfiles_backup_root() {
  printf '%s/dotfiles-backups\n' "$(ror_dotfiles_state_home)"
}

ror_dotfiles_list_backups() {
  local root dir
  root="$(ror_dotfiles_backup_root)"
  [ -d "$root" ] || { printf 'No dotfile backups found.\n'; return 0; }
  for dir in "$root"/*; do
    [ -d "$dir" ] || continue
    printf '%s' "$(basename "$dir")"
    if [ -f "$dir/meta" ]; then
      printf '  '
      tr '\n' ' ' < "$dir/meta"
    fi
    printf '\n'
  done
}

ror_dotfiles_resolve_backup() {
  local requested="${1:-latest}" root candidate
  root="$(ror_dotfiles_backup_root)"
  [ -d "$root" ] || return 1
  if [ "$requested" = 'latest' ]; then
    candidate="$(find "$root" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | sort | tail -n 1)"
  else
    candidate="$root/$requested"
  fi
  [ -d "$candidate" ] || return 1
  printf '%s\n' "$candidate"
}

ror_dotfiles_restore() {
  local requested="${1:-latest}" backup_dir manifest target backup existed
  backup_dir="$(ror_dotfiles_resolve_backup "$requested")" || {
    printf 'No matching dotfile backup: %s\n' "$requested" >&2
    return 1
  }
  manifest="$backup_dir/manifest.tsv"
  [ -f "$manifest" ] || { printf 'Backup manifest missing: %s\n' "$manifest" >&2; return 1; }

  while IFS=$'\t' read -r target backup existed; do
    [ -n "$target" ] || continue
    if [ "$existed" = '1' ]; then
      mkdir -p "$(dirname "$target")"
      cp -p "$backup" "$target"
      printf 'restored %s\n' "$target"
    else
      rm -f "$target"
      printf 'removed %s (did not exist before install)\n' "$target"
    fi
  done < "$manifest"
  printf 'Restored dotfiles from backup %s\n' "$(basename "$backup_dir")"
}
