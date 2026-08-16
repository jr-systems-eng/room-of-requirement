# Diagnostics

Read-only collectors intended to answer **what state is this machine in?** before making changes.

Use them directly with `ror run`, through the friendlier `ror diagnose` aliases, or capture the output with `ror collect`.

| Target | Script | Example |
|---|---|---|
| System | `system-info.sh` | `ror diagnose system` |
| Network | `network-info.sh` | `ror diagnose network` |
| systemd service | `systemd-service.sh` | `ror diagnose systemd sshd` |
| SSH server | `ssh-server.sh` | `ror diagnose ssh` |
| TLS endpoint | `tls-endpoint.sh` | `ror diagnose tls example.com:443` |
| DNS | `dns.sh` | `ror diagnose dns example.com` |
| Storage/LVM | `storage.sh` | `ror diagnose storage` |
| Java process | `java-process.sh` | `ror diagnose java 12345` |
| Tomcat | `tomcat.sh` | `ror diagnose tomcat tomcat` |

## Collection files

```bash
ror collect system
ror collect tls example.com:443
ror collect systemd sshd
```

Collection writes a timestamped text file to the current directory while also showing the output on screen. Set `ROR_COLLECT_OUTPUT` to choose a specific output path.

## Safety contract

Diagnostic scripts should not restart services, install packages, alter configuration, change permissions, or otherwise mutate the target system. Network diagnostics may make ordinary read-only connection/lookup attempts when that is the purpose of the collector.

Avoid collecting secrets. In particular, process environment blocks are intentionally excluded from Java/Tomcat diagnostics because they commonly contain credentials and tokens.
