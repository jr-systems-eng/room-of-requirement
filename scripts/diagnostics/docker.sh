#!/usr/bin/env bash
set -u

section() { printf '\n===== %s =====\n' "$1"; }
have() { command -v "$1" >/dev/null 2>&1; }

printf 'ROR Docker diagnostic\n'
printf 'Host: %s\n' "$(hostname -f 2>/dev/null || hostname 2>/dev/null || printf unknown)"
printf 'Date: %s\n' "$(date -Is 2>/dev/null || date)"

section 'CLIENT / DAEMON'
if ! have docker; then
  printf 'docker CLI unavailable\n'
  section 'SUMMARY'
  printf '[INFO] docker CLI is not installed or not on PATH.\n'
  exit 0
fi

docker --version 2>/dev/null || true
context="$(docker context show 2>/dev/null || true)"
[ -n "$context" ] && printf 'Context: %s\n' "$context"

server_version="$(docker version --format '{{.Server.Version}}' 2>/dev/null || true)"
if [ -n "$server_version" ]; then
  printf 'Server version: %s\n' "$server_version"
  daemon='reachable'
else
  printf 'Docker daemon/server information unavailable.\n'
  daemon='unreachable'
fi

section 'CONTAINERS'
docker ps -a --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}' 2>/dev/null || true

section 'COMPOSE PROJECTS'
docker compose ls 2>/dev/null || printf 'docker compose list unavailable\n'

section 'DISK USAGE'
docker system df 2>/dev/null || true

section 'SUMMARY'
if [ "$daemon" = 'reachable' ]; then
  total="$(docker ps -aq 2>/dev/null | sed '/^[[:space:]]*$/d' | wc -l | tr -d ' ')"
  running="$(docker ps -q 2>/dev/null | sed '/^[[:space:]]*$/d' | wc -l | tr -d ' ')"
  exited="$(docker ps -aq --filter status=exited 2>/dev/null | sed '/^[[:space:]]*$/d' | wc -l | tr -d ' ')"
  unhealthy="$(docker ps -q --filter health=unhealthy 2>/dev/null | sed '/^[[:space:]]*$/d' | wc -l | tr -d ' ')"
  printf '[OK]   Docker daemon reachable (server %s).\n' "$server_version"
  printf '[INFO] Containers: total=%s running=%s exited=%s unhealthy=%s.\n' "$total" "$running" "$exited" "$unhealthy"
  if [ "$unhealthy" -gt 0 ]; then
    printf '[WARN] %s running container(s) report an unhealthy healthcheck. Inspect container logs/healthcheck behavior without dumping environment variables.\n' "$unhealthy"
  fi
  if [ "$exited" -gt 0 ]; then
    printf '[INFO] %s exited container(s) are present; determine whether they are expected one-shot/stopped workloads before treating this as a fault.\n' "$exited"
  fi
else
  printf '[WARN] docker CLI is present but the configured Docker daemon/context was not reachable.\n'
fi
printf '[INFO] This collector intentionally does not inspect container environment variables or secret mounts.\n'
