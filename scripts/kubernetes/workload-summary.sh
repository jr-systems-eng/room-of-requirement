#!/usr/bin/env bash
set -u

command -v kubectl >/dev/null 2>&1 || { printf 'kubectl is required\n' >&2; exit 1; }

namespace="${1:-}"
if [ -z "$namespace" ]; then
  namespace="$(kubectl config view --minify -o 'jsonpath={..namespace}' 2>/dev/null || true)"
  [ -n "$namespace" ] || namespace='default'
fi

printf 'Context:   %s\n' "$(kubectl config current-context 2>/dev/null || printf unavailable)"
printf 'Namespace: %s\n' "$namespace"

printf '\n===== WORKLOADS =====\n'
kubectl get deployments,statefulsets,daemonsets -n "$namespace" -o wide

printf '\n===== PODS =====\n'
kubectl get pods -n "$namespace" -o wide

printf '\n===== SUMMARY =====\n'
problems="$(kubectl get pods -n "$namespace" --no-headers 2>/dev/null | awk '$3 != "Running" && $3 != "Completed" && $3 != "Succeeded" {count++} END {print count+0}')"
restarts="$(kubectl get pods -n "$namespace" --no-headers 2>/dev/null | awk '{sum += $4} END {print sum+0}')"
printf 'Non-running/non-completed pods: %s\n' "$problems"
printf 'Aggregate pod restart count:      %s\n' "$restarts"
printf 'No Secret objects or raw kubeconfig data are read by this utility.\n'
