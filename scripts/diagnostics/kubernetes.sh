#!/usr/bin/env bash
set -u

section() { printf '\n===== %s =====\n' "$1"; }
have() { command -v "$1" >/dev/null 2>&1; }

requested_ns="${1:-}"
printf 'ROR Kubernetes diagnostic\n'
printf 'Host: %s\n' "$(hostname -f 2>/dev/null || hostname 2>/dev/null || printf unknown)"
printf 'Date: %s\n' "$(date -Is 2>/dev/null || date)"

section 'CLIENT / CONTEXT'
if ! have kubectl; then
  printf 'kubectl unavailable\n'
  section 'SUMMARY'
  printf '[INFO] kubectl is not installed or not on PATH.\n'
  exit 0
fi

kubectl version --client=true 2>/dev/null || true
context="$(kubectl config current-context 2>/dev/null || true)"
printf 'Current context: %s\n' "${context:-unavailable}"

namespace="$requested_ns"
if [ -z "$namespace" ]; then
  namespace="$(kubectl config view --minify -o 'jsonpath={..namespace}' 2>/dev/null || true)"
  [ -n "$namespace" ] || namespace='default'
fi
printf 'Namespace: %s\n' "$namespace"

section 'CLUSTER REACHABILITY'
if kubectl get --raw=/readyz >/dev/null 2>&1; then
  cluster_state='reachable'
  printf 'API /readyz succeeded.\n'
else
  cluster_state='unreachable'
  kubectl cluster-info 2>/dev/null || true
fi

section 'NODES'
kubectl get nodes -o wide 2>/dev/null || true

section "WORKLOADS - $namespace"
kubectl get deployments,statefulsets,daemonsets -n "$namespace" -o wide 2>/dev/null || true

section "PODS - $namespace"
kubectl get pods -n "$namespace" -o wide 2>/dev/null || true

section "RECENT EVENTS - $namespace"
kubectl get events -n "$namespace" --sort-by=.lastTimestamp 2>/dev/null | tail -n 30 || true

section 'SUMMARY'
if [ "$cluster_state" = 'reachable' ]; then
  printf '[OK]   Kubernetes API is reachable using context %s.\n' "${context:-unknown}"

  node_not_ready="$(kubectl get nodes --no-headers 2>/dev/null | awk '$2 !~ /^Ready/ {count++} END {print count+0}')"
  pod_problem="$(kubectl get pods -n "$namespace" --no-headers 2>/dev/null | awk '$3 != "Running" && $3 != "Completed" && $3 != "Succeeded" {count++} END {print count+0}')"
  restarts="$(kubectl get pods -n "$namespace" --no-headers 2>/dev/null | awk '{sum += $4} END {print sum+0}')"

  if [ "$node_not_ready" -gt 0 ]; then
    printf '[WARN] %s node(s) are not reporting a Ready status.\n' "$node_not_ready"
  else
    printf '[OK]   No NotReady nodes observed.\n'
  fi

  if [ "$pod_problem" -gt 0 ]; then
    printf '[WARN] %s pod(s) in namespace %s are not Running/Completed in this snapshot.\n' "$pod_problem" "$namespace"
  else
    printf '[OK]   No non-Running/non-Completed pods observed in namespace %s.\n' "$namespace"
  fi
  printf '[INFO] Aggregate pod restart count in namespace %s: %s. Review per-pod age/restarts before treating this alone as a fault.\n' "$namespace" "$restarts"
else
  printf '[WARN] Kubernetes API was not reachable using the current kubeconfig/context.\n'
fi
printf '[INFO] This collector does not read Secret objects or print raw kubeconfig contents.\n'
