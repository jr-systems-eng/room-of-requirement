# Bash Snippets

Copy/paste building blocks for small administrative scripts.

## Safe script header

```bash
#!/usr/bin/env bash
set -euo pipefail
```

Use `set -e` deliberately; diagnostic/collection scripts often prefer explicit `|| true` handling so one unavailable command does not abort the entire report.

## Require an argument

```bash
target="${1:-}"
[ -n "$target" ] || { echo "Usage: $0 <target>" >&2; exit 2; }
```

## Check for a command

```bash
if command -v jq >/dev/null 2>&1; then
    jq --version
else
    echo "jq is not installed"
fi
```

## Loop over values

```bash
for service in sshd chronyd firewalld; do
    systemctl is-active "$service" || true
done
```

## Read a file safely, preserving whitespace

```bash
while IFS= read -r line; do
    printf '%s\n' "$line"
done < input.txt
```

## Read command output line by line

```bash
while IFS= read -r host; do
    echo "Checking $host"
done < <(awk '{print $1}' hosts.txt)
```

## Temporary file with cleanup

```bash
tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT
```

## Timestamp

```bash
stamp="$(date +%Y%m%d-%H%M%S)"
```

## Script directory / repo-relative path

```bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
```

## Default value

```bash
port="${PORT:-443}"
```

## Case statement

```bash
case "$1" in
    start) echo "start" ;;
    stop)  echo "stop" ;;
    *) echo "Usage: $0 start|stop" >&2; exit 2 ;;
esac
```

## Capture command output and status

```bash
output="$(some_command 2>&1)"
rc=$?
printf '%s\n' "$output"
echo "rc=$rc"
```

## Tee output while preserving command status

```bash
some_command 2>&1 | tee output.log
rc=${PIPESTATUS[0]}
```

## Confirm before a destructive action

```bash
read -r -p "Continue? [y/N] " answer
case "$answer" in
    y|Y|yes|YES) ;;
    *) echo "Cancelled"; exit 1 ;;
esac
```
