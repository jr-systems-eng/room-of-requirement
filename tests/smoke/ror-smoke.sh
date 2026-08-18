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
check "${ROR[@]}" path room >/dev/null
check "${ROR[@]}" find ssh >/dev/null
check "${ROR[@]}" find --type runbook ssh >/dev/null
PAGER=cat check "${ROR[@]}" cheat subnetting >/dev/null

need_list="$("${ROR[@]}" need list)"
for topic in ssh tomcat nfs performance terraform github containers kubernetes; do
  printf '%s\n' "$need_list" | grep -q "$topic"
done

need_ssh="$("${ROR[@]}" need ssh)"
printf '%s\n' "$need_ssh" | grep -q '^Room of Requirement: ssh$'
printf '%s\n' "$need_ssh" | grep -q '^Start here:$'
printf '%s\n' "$need_ssh" | grep -q '^Related rooms:$'
printf '%s\n' "$need_ssh" | grep -q 'troubleshoot-ssh-connection.md'

need_cert="$("${ROR[@]}" need certificate)"
printf '%s\n' "$need_cert" | grep -q '^Room of Requirement: tls$'
printf '%s\n' "$need_cert" | grep -q 'cert-expiry.sh'

need_nfs="$("${ROR[@]}" need nfs)"
printf '%s\n' "$need_nfs" | grep -q '^Room of Requirement: nfs$'
printf '%s\n' "$need_nfs" | grep -q 'scripts/diagnostics/nfs.sh'
printf '%s\n' "$need_nfs" | grep -q 'configure-nfs-share.md'

need_perf="$("${ROR[@]}" need memory)"
printf '%s\n' "$need_perf" | grep -q '^Room of Requirement: performance$'
printf '%s\n' "$need_perf" | grep -q 'scripts/diagnostics/performance.sh'
printf '%s\n' "$need_perf" | grep -q 'investigate-memory-pressure.md'

need_containers="$("${ROR[@]}" need docker)"
printf '%s\n' "$need_containers" | grep -q '^Room of Requirement: containers$'
printf '%s\n' "$need_containers" | grep -q 'scripts/diagnostics/docker.sh'

need_k8s="$("${ROR[@]}" need kubernetes)"
printf '%s\n' "$need_k8s" | grep -q 'scripts/diagnostics/kubernetes.sh'
printf '%s\n' "$need_k8s" | grep -q 'templates/k8s/deployment.yaml'

# Runtime and Python validation both protect the metadata/resource graph.
# shellcheck source=../../lib/resources.sh
. "$ROOT/lib/resources.sh"
export ROR_HOME="$ROOT"
while IFS= read -r topic; do
  while IFS='|' read -r _type path _note; do
    [ -n "$path" ] || continue
    [ -e "$ROOT/$path" ] || {
      printf 'Missing curated resource for %s: %s\n' "$topic" "$path" >&2
      exit 1
    }
  done < <(ror_need_resources "$topic")
done < <(ror_need_topics)

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

check "${ROR[@]}" new ansible/rolling-change.yml "$TMPDIR_ROR/rolling-change.yml" >/dev/null
check "${ROR[@]}" new k8s/ingress.yaml "$TMPDIR_ROR/ingress.yaml" >/dev/null
check "${ROR[@]}" new terraform/module.tf "$TMPDIR_ROR/main.tf" >/dev/null
[ -s "$TMPDIR_ROR/rolling-change.yml" ]
[ -s "$TMPDIR_ROR/ingress.yaml" ]
[ -s "$TMPDIR_ROR/main.tf" ]

repo_health="$("${ROR[@]}" run git/repo-health.sh "$ROOT")"
printf '%s\n' "$repo_health" | grep -q '^Repository:'
printf '%s\n' "$repo_health" | grep -q 'remote URLs are intentionally not printed'

printf 'ROR smoke tests passed.\n'
