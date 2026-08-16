# Bash Scripting

Quick-reference for writing safer administrative shell scripts and one-liners.

## Shebang and safe defaults

```bash
#!/usr/bin/env bash
set -euo pipefail
```

Meaning:

```text
-e          exit when an unhandled command fails
-u          error on unset variables
-o pipefail fail a pipeline if any component fails
```

Use deliberately: some scripts need explicit handling around commands that may legitimately return non-zero.

## Variables

```bash
name='value'
echo "$name"
echo "${name}suffix"
readonly CONFIG='/etc/app.conf'
```

Quote variable expansions unless you intentionally want word splitting/globbing:

```bash
cp "$source" "$destination"
```

## Arguments

```bash
$0      script name
$1      first argument
$2      second argument
$#      argument count
$@      all arguments
$?      previous exit code
$$      current shell PID
```

Recommended iteration:

```bash
for arg in "$@"; do
    echo "$arg"
done
```

## Conditions

```bash
if [[ -f "$file" ]]; then
    echo 'file exists'
elif [[ -d "$file" ]]; then
    echo 'directory exists'
else
    echo 'not found'
fi
```

Useful tests:

```text
-f FILE      regular file
-d DIR       directory
-e PATH      exists
-r FILE      readable
-w FILE      writable
-x FILE      executable
-z STRING    empty
-n STRING    non-empty
```

String/numeric:

```bash
[[ "$a" == "$b" ]]
[[ "$a" != "$b" ]]
[[ "$n" -eq 5 ]]
[[ "$n" -gt 5 ]]
```

## Command success

```bash
if command; then
    echo 'success'
else
    echo 'failed'
fi
```

Check command exists:

```bash
if ! command -v curl >/dev/null 2>&1; then
    echo 'curl is required' >&2
    exit 1
fi
```

## Loops

```bash
for item in one two three; do
    echo "$item"
done
```

Read a file safely:

```bash
while IFS= read -r line; do
    echo "$line"
done < input.txt
```

## Functions

```bash
log() {
    printf '%s %s\n' "$(date '+%F %T')" "$*"
}

fail() {
    echo "ERROR: $*" >&2
    exit 1
}
```

## Command substitution

```bash
kernel=$(uname -r)
today=$(date +%F)
```

## Here document

```bash
cat <<'EOF' > file.conf
literal $text is not expanded
EOF
```

Expand variables:

```bash
cat <<EOF > file.conf
value=$value
EOF
```

## Temporary files/directories

```bash
tmp=$(mktemp)
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT
```

## Traps

```bash
cleanup() {
    rm -f "$tmp"
}
trap cleanup EXIT
```

Signals:

```bash
trap 'echo interrupted; exit 130' INT TERM
```

## Read a secret without echo/history

```bash
read -rsp 'Password: ' password
echo
```

Do not pass secrets directly on command lines when avoidable because process listings may expose them.

## Arrays

```bash
hosts=(server1 server2 server3)
for host in "${hosts[@]}"; do
    echo "$host"
done
```

## Case statement

```bash
case "$1" in
    start) echo 'starting' ;;
    stop)  echo 'stopping' ;;
    *)     echo "Usage: $0 {start|stop}" >&2; exit 2 ;;
esac
```

## Exit codes

```text
0     success
1     general failure
2     common usage/argument error
126   found but not executable
127   command not found
128+n terminated by signal n
```

## Debugging

Syntax check:

```bash
bash -n script.sh
```

Trace execution:

```bash
bash -x script.sh
```

Inside script:

```bash
set -x
# commands
set +x
```

Never enable tracing around secrets.

## shellcheck

```bash
shellcheck script.sh
```

Excellent first pass for quoting, unsafe expansions, and common scripting mistakes.

## Safe admin-script skeleton

```bash
#!/usr/bin/env bash
set -euo pipefail

usage() {
    echo "Usage: $0 <argument>" >&2
}

[[ $# -eq 1 ]] || { usage; exit 2; }

arg=$1

command -v required_tool >/dev/null 2>&1 || {
    echo 'required_tool is required' >&2
    exit 1
}

# work here
```
