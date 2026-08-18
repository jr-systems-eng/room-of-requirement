#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
ROR=(bash "$ROOT/bin/ror")
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

workflow_list="$("${ROR[@]}" workflow list)"
for workflow in nfs-client service-recovery workstation ansible-inventory certificate-deploy-prep; do
  grep -q "$workflow" <<< "$workflow_list"
done
grep -q 'experimental' <<< "$workflow_list"

version_output="$("${ROR[@]}" version)"
grep -q '^Room of Requirement v0\.9\.0$' <<< "$version_output"
[ "$("${ROR[@]}" path workflows)" = "$ROOT/workflows" ]
[ "$("${ROR[@]}" path workflow-metadata)" = "$ROOT/config/workflows" ]

for workflow in nfs-client service-recovery workstation ansible-inventory certificate-deploy-prep; do
  "${ROR[@]}" workflow "$workflow" --help >/dev/null
done

if "${ROR[@]}" workflow definitely-not-a-workflow >/dev/null 2>&1; then
  printf 'Unknown workflow unexpectedly succeeded.\n' >&2
  exit 1
fi

stub="$TMP/bin"
mkdir -p "$stub" "$TMP/mountpoint"
cat > "$stub/mount.nfs" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
cat > "$stub/findmnt" <<'EOF'
#!/usr/bin/env bash
exit 1
EOF
cat > "$stub/getent" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
cat > "$stub/nc" <<'EOF'
#!/usr/bin/env bash
exit 1
EOF
chmod +x "$stub"/*

nfs_plan="$(PATH="$stub:$PATH" "${ROR[@]}" workflow nfs-client --server localhost --export /data --mountpoint "$TMP/mountpoint")"
grep -q '^Changes: NONE (plan/preflight only)\.$' <<< "$nfs_plan"
grep -q 'Mount localhost:/data' <<< "$nfs_plan"
[ -z "$(find "$TMP/mountpoint" -mindepth 1 -maxdepth 1 -print -quit)" ]

ansible_stub="$TMP/ansible-bin"
mkdir -p "$ansible_stub"
cat > "$ansible_stub/ansible-inventory" <<'EOF'
#!/usr/bin/env bash
case " $* " in
  *' --version '*) printf 'ansible-inventory [core test]\n' ;;
  *' --graph '*) printf '@all:\n  |--@ungrouped:\n' ;;
  *' --host '*) printf '{}\n' ;;
  *' --list '*) printf '{}\n' ;;
  *) exit 0 ;;
esac
EOF
chmod +x "$ansible_stub/ansible-inventory"
printf '[all]\nlocalhost ansible_connection=local\n' > "$TMP/hosts.ini"
PATH="$ansible_stub:$PATH" "${ROR[@]}" workflow ansible-inventory --inventory "$TMP/hosts.ini" >/dev/null

"${ROR[@]}" self-test >/dev/null
printf 'Workflow smoke tests passed.\n'
