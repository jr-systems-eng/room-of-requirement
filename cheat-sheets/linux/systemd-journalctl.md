# systemd and journalctl

Quick-reference for service troubleshooting, startup failures, and log inspection.

## Service status and lifecycle

```bash
systemctl status SERVICE --no-pager -l
systemctl start SERVICE
systemctl stop SERVICE
systemctl restart SERVICE
systemctl reload SERVICE
systemctl enable SERVICE
systemctl disable SERVICE
systemctl enable --now SERVICE
systemctl is-active SERVICE
systemctl is-enabled SERVICE
systemctl list-units --type=service --state=failed
```

## Unit details

```bash
systemctl cat SERVICE
systemctl show SERVICE
systemctl show SERVICE -p ExecStart -p User -p Group
systemctl list-dependencies SERVICE
systemctl daemon-reload
systemd-analyze verify /etc/systemd/system/example.service
```

Use `daemon-reload` after changing a unit file or drop-in.

## Logs for a service

```bash
journalctl -u SERVICE
journalctl -u SERVICE -n 100
journalctl -u SERVICE -f
journalctl -u SERVICE --since today
journalctl -u SERVICE --since '1 hour ago'
journalctl -u SERVICE --since '2026-08-16 13:00' --until '2026-08-16 14:00'
```

## System-wide logs

```bash
journalctl -b                              # Current boot
journalctl -b -1                           # Previous boot
journalctl -p err..alert                   # Error and worse
journalctl --since today
journalctl -k                              # Kernel messages
journalctl -xe                             # Recent contextual messages
```

## Filter useful fields

```bash
journalctl _PID=1234
journalctl _COMM=sshd
journalctl SYSLOG_IDENTIFIER=sshd
journalctl _SYSTEMD_UNIT=sshd.service
```

## Common failure workflow

```bash
systemctl status SERVICE --no-pager -l
journalctl -u SERVICE -n 100 --no-pager
systemctl cat SERVICE
systemctl show SERVICE -p ExecStart -p User -p Group
```

Then inspect the command manually when safe:

```bash
/usr/bin/program --config /path/to/config
```

## After editing a unit

```bash
systemctl daemon-reload
systemctl restart SERVICE
systemctl status SERVICE --no-pager -l
journalctl -u SERVICE -n 50 --no-pager
```

## Common service locations

```text
/usr/lib/systemd/system/      vendor units
/etc/systemd/system/          local overrides/custom units
/etc/systemd/system/*.d/      drop-ins
/run/systemd/system/          runtime units
```

Prefer a drop-in over editing a vendor unit directly:

```bash
systemctl edit SERVICE
```
