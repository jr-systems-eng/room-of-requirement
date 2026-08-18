#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
ROR=(bash "$ROOT/bin/ror")
TMPDIR_ROR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR_ROR"' EXIT
STUBBIN="$TMPDIR_ROR/bin"
mkdir -p "$STUBBIN"

cat > "$STUBBIN/docker" <<'EOF'
#!/usr/bin/env bash
set -u
joined="$*"
case "${1:-}" in
  --version)
    printf 'Docker version 99.0.0, build test\n'
    ;;
  version)
    printf '99.0.0\n'
    ;;
  context)
    printf 'test-context\n'
    ;;
  ps)
    case "$joined" in
      *health=unhealthy*) ;;
      *status=exited*) printf 'deadbeef\n' ;;
      *'-aq'*) printf 'run123\ndeadbeef\n' ;;
      *'-q'*) printf 'run123\n' ;;
      *'--format'*) printf 'NAMES IMAGE STATUS PORTS\ntest-app example:test Up 1 hour 127.0.0.1:8080->8080/tcp\n' ;;
    esac
    ;;
  compose)
    printf 'NAME STATUS CONFIG FILES\ntest running compose.yaml\n'
    ;;
  system)
    printf 'TYPE TOTAL ACTIVE SIZE RECLAIMABLE\nImages 1 1 10MB 0B\n'
    ;;
esac
EOF
chmod +x "$STUBBIN/docker"

cat > "$STUBBIN/kubectl" <<'EOF'
#!/usr/bin/env bash
set -u
joined="$*"
case "${1:-}" in
  version)
    printf 'Client Version: v9.9.9-test\n'
    ;;
  config)
    case "${2:-}" in
      current-context) printf 'test-context\n' ;;
      view) printf 'testns\n' ;;
    esac
    ;;
  get)
    if [[ "$joined" == *'--raw=/readyz'* ]]; then
      printf 'ok\n'
    elif [[ "$joined" == *'nodes --no-headers'* ]]; then
      printf 'node1 Ready control-plane 1d v9.9.9\n'
    elif [[ "$joined" == *'nodes -o wide'* ]]; then
      printf 'NAME STATUS ROLES AGE VERSION\nnode1 Ready control-plane 1d v9.9.9\n'
    elif [[ "$joined" == *'pods'*'--no-headers'* ]]; then
      printf 'app-123 1/1 Running 0 1h\n'
    elif [[ "$joined" == *'pods'* ]]; then
      printf 'NAME READY STATUS RESTARTS AGE IP NODE\napp-123 1/1 Running 0 1h 10.0.0.10 node1\n'
    elif [[ "$joined" == *'events'* ]]; then
      printf 'LAST SEEN TYPE REASON OBJECT MESSAGE\n1m Normal Started pod/app-123 Started container\n'
    elif [[ "$joined" == *'deployments,statefulsets,daemonsets'* ]]; then
      printf 'NAME READY UP-TO-DATE AVAILABLE AGE\ndeployment.apps/app 1/1 1 1 1h\n'
    fi
    ;;
  cluster-info)
    printf 'Kubernetes control plane is running\n'
    ;;
esac
EOF
chmod +x "$STUBBIN/kubectl"

PATH="$STUBBIN:$PATH" docker_output="$(PATH="$STUBBIN:$PATH" "${ROR[@]}" diagnose docker)"
printf '%s\n' "$docker_output" | grep -q '^===== SUMMARY =====$'
printf '%s\n' "$docker_output" | grep -q 'Docker daemon reachable'
printf '%s\n' "$docker_output" | grep -q 'unhealthy=0'

PATH="$STUBBIN:$PATH" k8s_output="$(PATH="$STUBBIN:$PATH" "${ROR[@]}" diagnose kubernetes testns)"
printf '%s\n' "$k8s_output" | grep -q '^===== SUMMARY =====$'
printf '%s\n' "$k8s_output" | grep -q 'Kubernetes API is reachable using context test-context'
printf '%s\n' "$k8s_output" | grep -q 'No NotReady nodes observed'

printf 'External diagnostic stub smoke tests passed.\n'
