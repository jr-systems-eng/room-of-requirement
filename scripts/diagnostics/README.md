# Diagnostics

Read-only collectors intended to answer **what state is this machine in?** before making changes.

Use them directly with `ror run`, through the friendlier `ror diagnose` aliases, or capture the output with `ror collect`.

| Target | Script | Example |
|---|---|---|
| Baseline intake | `baseline.sh` | `ror collect baseline` |
| System | `system-info.sh` | `ror diagnose system` |
| Network | `network-info.sh` | `ror diagnose network` |
| systemd service | `systemd-service.sh` | `ror diagnose systemd sshd` |
| SSH server | `ssh-server.sh` | `ror diagnose ssh` |
| TLS endpoint | `tls-endpoint.sh` | `ror diagnose tls example.com:443` |
| DNS | `dns.sh` | `ror diagnose dns example.com` |
| Storage/LVM | `storage.sh` | `ror diagnose storage` |
| Java process | `java-process.sh` | `ror diagnose java 12345` |
| Tomcat | `tomcat.sh` | `ror diagnose tomcat tomcat` |

## Baseline intake

`ror collect baseline` is the general-purpose first look at an unfamiliar host. It combines system, network, storage, and resolver state with security-mode visibility, firewall state, time synchronization, failed services, recent warning-or-higher journal entries, kernel package information, and reboot status.

The baseline path deliberately skips the potentially expensive top-level `du /` scan. Use `ror diagnose storage` when the deeper directory-size scan is appropriate.

The baseline intentionally reports only whether common proxy variables are present rather than printing their values. Process environment blocks are also excluded because they commonly contain credentials and tokens.

## Interpreted summaries

The systemd, SSH, TLS, DNS, storage, Java, and Tomcat collectors end with a `SUMMARY` section when they can make useful observations from direct evidence.

Typical summary signals include:

- systemd unit load/active state and last main-process exit status;
- SSH daemon activity, config validation, listener state, and selected KEX/authentication log patterns;
- TLS certificate receipt, OpenSSL verification result, hostname match where supported, and expiry windows;
- resolver configuration, system-resolver success, and DNS response status;
- filesystem/inode thresholds and deleted-but-open files;
- Java runtime/process presence and whether a requested PID appears to be Java;
- Tomcat service/PID state plus selected `OutOfMemoryError`, PKIX, bind-conflict, and connection-failure patterns.

Interpretation is intentionally conservative. `WARN` means **inspect this evidence**, not **the root cause is proven**. Raw command output remains above the summary so every observation can be checked.

## Collection files

```bash
ror collect baseline
ror collect system
ror collect tls example.com:443
ror collect systemd sshd
```

Collection writes a timestamped text file to the current directory while also showing the output on screen. Set `ROR_COLLECT_OUTPUT` to choose a specific output path.

## Safety contract

Diagnostic scripts should not restart services, install packages, alter configuration, change permissions, or otherwise mutate the target system. Network diagnostics may make ordinary read-only connection/lookup attempts when that is the purpose of the collector.

Avoid collecting secrets. In particular, process environment blocks are intentionally excluded from Java/Tomcat diagnostics because they commonly contain credentials and tokens. The Tomcat collector also excludes the systemd `Environment` property for the same reason.
