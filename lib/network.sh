#!/usr/bin/env bash

ror_default_gateway() {
  if command -v ip >/dev/null 2>&1; then
    ip route 2>/dev/null | awk '/^default/ {print $3; exit}'
  elif command -v route >/dev/null 2>&1; then
    route -n get default 2>/dev/null | awk '/gateway:/ {print $2; exit}'
  fi
}

ror_primary_ip() {
  if command -v ip >/dev/null 2>&1; then
    ip route get 1.1.1.1 2>/dev/null | awk '{for(i=1;i<=NF;i++) if($i=="src") {print $(i+1); exit}}'
  elif command -v hostname >/dev/null 2>&1; then
    hostname -I 2>/dev/null | awk '{print $1}'
  fi
}
