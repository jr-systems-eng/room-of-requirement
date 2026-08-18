#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ROR=(bash "$ROOT/bin/ror")

printf 'ROR self-test\n'
printf '%s\n' '----------------------------------------'

[ -r "$ROOT/VERSION" ]
version="$(tr -d '\r\n' < "$ROOT/VERSION")"
[[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]
printf '[OK] VERSION: %s\n' "$version"

for path in config/room config/workflows workflows scripts/diagnostics tests; do
  [ -e "$ROOT/$path" ] || { printf '[FAIL] missing %s\n' "$path" >&2; exit 1; }
  printf '[OK] %s\n' "$path"
done

while IFS= read -r -d '' file; do
  bash -n "$file"
done < <(find "$ROOT/bin" "$ROOT/lib" "$ROOT/workflows" -type f -name '*.sh' -print0)
printf '[OK] core Bash syntax\n'

if command -v python3 >/dev/null 2>&1; then
  python3 "$ROOT/tests/validate_room_metadata.py"
  python3 "$ROOT/tests/validate_workflow_metadata.py"
else
  printf '[SKIP] python3 unavailable; metadata validators not run\n'
fi

"${ROR[@]}" help >/dev/null
"${ROR[@]}" need list >/dev/null
"${ROR[@]}" workflow list >/dev/null
version_output="$("${ROR[@]}" version)"
grep -q "v${version}" <<< "$version_output"
printf '[OK] CLI discovery/version/workflow dispatch\n'

printf 'Self-test passed.\n'
