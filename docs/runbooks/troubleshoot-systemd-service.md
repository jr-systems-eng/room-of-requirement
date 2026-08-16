# Troubleshoot a systemd Service

## Symptoms

- Service is failed, inactive, restarting, or exits immediately.
- Application is unavailable after reboot/deploy.
- `systemctl start` or `restart` returns a failure.

## Safety

Start read-only. Do not restart or modify the unit until the failure mode is understood.

## First checks

```bash
ror diagnose systemd <service>
# or
systemctl status <service> --no-pager -l
systemctl show <service> -p MainPID -p ExecStart -p User -p Group -p Environment
journalctl -u <service> -n 100 --no-pager
```

## Decision path

### Unit not found

```bash
systemctl list-unit-files | grep -i <name>
systemctl cat <service>
```

Check aliases, package ownership, and whether the unit lives under `/etc/systemd/system`, `/usr/lib/systemd/system`, or `/lib/systemd/system`.

### Process exits immediately

Read the first application error in the journal, not only the final systemd summary. Check:

```bash
systemctl cat <service>
namei -l /path/to/executable
sudo -u <service-user> test -r /path/to/config
```

Look for bad paths, permissions, missing libraries/configuration, port conflicts, and invalid environment variables.

### Port already in use

```bash
ss -lntp
lsof -i :<port>
```

### Unit changed on disk

```bash
systemctl daemon-reload
```

Only run this after verifying the intended unit change.

## Validation after remediation

```bash
systemctl is-active <service>
systemctl status <service> --no-pager -l
journalctl -u <service> --since '-5 min' --no-pager
ss -lntp
```

Confirm the application itself is reachable; an `active` service is not sufficient proof.
