#!/usr/bin/env bash

ror_info() { printf '[INFO] %s\n' "$*"; }
ror_warn() { printf '[WARN] %s\n' "$*" >&2; }
ror_error() { printf '[ERROR] %s\n' "$*" >&2; }
