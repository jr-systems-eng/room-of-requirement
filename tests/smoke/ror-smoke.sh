#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
ROR=(bash "$ROOT/bin/ror")
TMPDIR_ROR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR_ROR"' EXIT

check() {
  printf 'SMOKE: %s\n' "$*"
  "$@"
}

check "${ROR[@]}" help >/dev/null
check "${ROR[@]}" info >/dev/null
check "${ROR[@]}" path scripts >/dev/null
check "${ROR[@]}" find ssh >/dev/null
check "${ROR[@]}" find --type runbook ssh >/dev/null
PAGER=cat check "${ROR[@]}" cheat subnetting >/dev/null

need_list="$("${ROR[@]}" need list)"
printf '%s\n' "$need_list" | grep -q 'ssh'
printf '%s\n' "$need_list" | grep -q 'tomcat'
need_ssh="$("${ROR[@]}" need ssh)"
printf '%s\n' "$need_ssh" | grep -q '^Room of Requirement: ssh$'
printf '%s\n' "$need_ssh" | grep -q 'troubleshoot-ssh-connection.md'
need_cert="$("${ROR[@]}" need certificate)"
printf '%s\n' "$need_cert" | grep -q '^Room of Requirement: tls$'

pkg_list="$("${ROR[@]}" pkg list)"
printf '%s\n' "$pkg_list" | grep -q 'minimal'
printf '%s\n' "$pkg_list" | grep -q 'linux-admin'
printf '%s\n' "$pkg_list" | grep -q 'kubernetes'
[ "$(printf '%s\n' "$pkg_list" | wc -l | tr -d ' ')" -eq 10 ]
check "${ROR[@]}" pkg suggest minimal >/dev/null

check "${ROR[@]}" dotfiles status >/dev/null
check "${ROR[@]}" dotfiles diff bash >/dev/null
check "${ROR[@]}" diagnose system >/dev/null

dns_output="$("${ROR[@]}" diagnose dns localhost)"
printf '%s\n' "$dns_output" | grep -q '^===== SUMMARY =====$'

java_output="$("${ROR[@]}" diagnose java)"
printf '%s\n' "$java_output" | grep -q '^===== SUMMARY =====$'

ROR_COLLECT_OUTPUT="$TMPDIR_ROR/system.txt" check "${ROR[@]}" collect system >/dev/null
[ -s "$TMPDIR_ROR/system.txt" ]

ROR_COLLECT_OUTPUT="$TMPDIR_ROR/baseline.txt" check "${ROR[@]}" collect baseline >/dev/null
[ -s "$TMPDIR_ROR/baseline.txt" ]

printf 'ROR smoke tests passed.\n'
