#!/usr/bin/env bash
set -u

section() { printf '\n===== %s =====\n' "$1"; }
have() { command -v "$1" >/dev/null 2>&1; }

target="${1:-}"
mount_count='unknown'
server_state='unknown'
listener_state='unknown'
target_state='not requested'

printf 'ROR NFS diagnostic\n'
printf 'Host: %s\n' "$(hostname -f 2>/dev/null || hostname 2>/dev/null || printf unknown)"
printf 'Date: %s\n' "$(date -Is 2>/dev/null || date)"
[ -n "$target" ] && printf 'Remote server check: %s\n' "$target"

section 'NFS CLIENT MOUNTS'
if have findmnt; then
  findmnt -t nfs,nfs4 2>/dev/null || true
  mount_count="$(findmnt -rn -t nfs,nfs4 2>/dev/null | sed '/^[[:space:]]*$/d' | wc -l | tr -d ' ')"
else
  mount -t nfs,nfs4 2>/dev/null || true
  printf 'findmnt unavailable\n'
fi

if have nfsstat; then
  printf '\nNegotiated mount options:\n'
  nfsstat -m 2>/dev/null || true
fi

section 'NFS SERVER EXPORTS'
if [ -r /etc/exports ]; then
  grep -vE '^[[:space:]]*(#|$)' /etc/exports 2>/dev/null || true
else
  printf '/etc/exports not present/readable\n'
fi
if have exportfs; then
  printf '\nLoaded exports:\n'
  exportfs -v 2>/dev/null || true
else
  printf 'exportfs unavailable\n'
fi

section 'SERVER SERVICE / LISTENER'
if have systemctl; then
  server_state="$(systemctl is-active nfs-server 2>/dev/null || true)"
  [ -n "$server_state" ] || server_state='unknown'
  systemctl status nfs-server --no-pager -l 2>/dev/null | head -n 40 || true
else
  printf 'systemctl unavailable\n'
fi

if have ss; then
  if ss -lnt 2>/dev/null | grep -qE '(^|[[:space:]])[^[:space:]]*:2049([[:space:]]|$)'; then
    listener_state='listening'
  else
    listener_state='not observed'
  fi
  ss -lntup 2>/dev/null | awk 'NR==1 || $5 ~ /:2049$/' || true
else
  printf 'ss unavailable\n'
fi

if have rpcinfo; then
  printf '\nRPC programs:\n'
  rpcinfo -p localhost 2>/dev/null || true
fi

section 'RECENT NFS KERNEL / SERVICE EVENTS'
if have journalctl; then
  journalctl -k -b --no-pager 2>/dev/null | grep -iE 'nfs|rpc' | tail -n 50 || true
  journalctl -u nfs-server -n 50 --no-pager 2>/dev/null || true
else
  printf 'journalctl unavailable\n'
fi

if [ -n "$target" ]; then
  section 'REMOTE SERVER REACHABILITY'
  if have getent; then
    getent ahosts "$target" 2>/dev/null | head -n 10 || true
  fi
  if have nc; then
    if nc -z -w 3 "$target" 2049 >/dev/null 2>&1; then
      target_state='TCP/2049 reachable'
      printf 'TCP/2049 reachable on %s\n' "$target"
    else
      target_state='TCP/2049 not reachable'
      printf 'TCP/2049 connection failed for %s\n' "$target"
    fi
  else
    target_state='nc unavailable'
    printf 'nc unavailable; remote TCP/2049 check skipped\n'
  fi
fi

section 'SUMMARY'
if [[ "$mount_count" =~ ^[0-9]+$ ]]; then
  printf '[INFO] NFS mounts currently visible: %s.\n' "$mount_count"
else
  printf '[INFO] NFS mount count unavailable.\n'
fi

case "$server_state" in
  active) printf '[OK]   nfs-server is active on this host.\n' ;;
  inactive|failed) printf '[INFO] nfs-server is %s; that is normal for a client-only host.\n' "$server_state" ;;
  *) printf '[INFO] nfs-server state unavailable: %s.\n' "$server_state" ;;
esac

case "$listener_state" in
  listening) printf '[OK]   TCP/2049 listener observed locally.\n' ;;
  'not observed') printf '[INFO] No local TCP/2049 listener observed; expected on a client-only host.\n' ;;
  *) printf '[INFO] Local TCP/2049 listener status unavailable.\n' ;;
esac

if [ -n "$target" ]; then
  case "$target_state" in
    'TCP/2049 reachable') printf '[OK]   Remote server %s is reachable on TCP/2049.\n' "$target" ;;
    'TCP/2049 not reachable') printf '[WARN] Remote server %s was not reachable on TCP/2049 from this host.\n' "$target" ;;
    *) printf '[INFO] Remote reachability result: %s.\n' "$target_state" ;;
  esac
fi
printf '[INFO] NFS permission/export correctness still requires export and UID/GID evidence; port reachability alone does not prove a working mount.\n'
