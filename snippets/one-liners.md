# Useful One-Liners

## Files and disk

```bash
# Largest files under a path
find /path -xdev -type f -printf '%s %p\n' 2>/dev/null | sort -n | tail -n 50

# Largest immediate directories
du -x -h --max-depth=1 /path 2>/dev/null | sort -h

# Files modified in the last 24 hours
find /path -type f -mtime -1 -ls

# Deleted files still held open
lsof +L1

# Count files by extension
find /path -type f -name '*.*' | sed 's/.*\.//' | sort | uniq -c | sort -nr
```

## Processes / services

```bash
# Top CPU users
ps -eo pid,user,comm,%cpu,%mem --sort=-%cpu | head

# Top memory users
ps -eo pid,user,comm,%mem,%cpu --sort=-%mem | head

# Failed systemd units
systemctl --failed --no-pager

# Recent service errors
journalctl -u sshd -p warning --since '-1 hour' --no-pager
```

## Networking

```bash
# Listening TCP/UDP sockets
ss -lntup

# Route the kernel would use
ip route get 8.8.8.8

# Test TCP port
nc -vz host.example.com 443

# Public-facing certificate dates
openssl s_client -connect host.example.com:443 -servername host.example.com </dev/null 2>/dev/null | openssl x509 -noout -subject -issuer -dates
```

## Text / logs

```bash
# Errors with context
grep -Ein -B3 -A8 'error|failed|exception|denied' app.log

# Count repeated matching lines
grep -Ei 'error|failed' app.log | sort | uniq -c | sort -nr

# Follow a rotated log safely
tail -F /var/log/app.log
```

## Accounts

```bash
# Human-style local accounts (common Linux convention)
awk -F: '$3 >= 1000 && $3 != 65534 {print $1,$3,$6,$7}' /etc/passwd

# Show groups
id username

# Resolve every path component's permissions
namei -l /path/to/file
```
