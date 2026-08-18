# Diagnostics

Read-only collectors intended to answer **what state is this machine/workload in?** before making changes.

Use them directly with `ror run`, through `ror diagnose`, or capture the same output with `ror collect`.

| Target | Script | Example |
|---|---|---|
| Baseline intake | `baseline.sh` | `ror collect baseline` |
| System | `system-info.sh` | `ror diagnose system` |
| Performance | `performance.sh` | `ror diagnose performance` |
| Network | `network-info.sh` | `ror diagnose network` |
| NFS | `nfs.sh` | `ror diagnose nfs nfs.example.com` |
| systemd service | `systemd-service.sh` | `ror diagnose systemd sshd` |
| SSH server | `ssh-server.sh` | `ror diagnose ssh` |
| TLS endpoint | `tls-endpoint.sh` | `ror diagnose tls example.com:443` |
| DNS | `dns.sh` | `ror diagnose dns example.com` |
| Storage/LVM | `storage.sh` | `ror diagnose storage` |
| Docker | `docker.sh` | `ror diagnose docker` |
| Kubernetes | `kubernetes.sh` | `ror diagnose kubernetes default` |
| Java process | `java-process.sh` | `ror diagnose java 12345` |
| Tomcat | `tomcat.sh` | `ror diagnose tomcat tomcat` |

## Baseline intake

`ror collect baseline` is the general-purpose first look at an unfamiliar host. It combines system, network, storage, resolver, security-mode, firewall, time-sync, failed-service, journal, kernel-package, and reboot state. The baseline skips the potentially expensive top-level `du /` scan.

Proxy variables are reported as present/not-present rather than by value. Process environment blocks are excluded because they commonly contain credentials and tokens.

## Interpreted summaries

High-value targeted collectors end with a `SUMMARY` section when direct evidence supports useful observations.

Phase 7 adds:

- performance summary signals for load relative to CPU count, `MemAvailable`, D-state tasks, and OOM journal evidence;
- NFS client/server visibility plus optional remote TCP/2049 reachability without pretending port reachability proves export/permission correctness;
- Docker daemon/context/container-state observations without inspecting container environments;
- Kubernetes API/node/pod observations without reading Secret objects or printing raw kubeconfig.

Existing summaries cover systemd, SSH, TLS, DNS, storage, Java, and Tomcat.

Interpretation is intentionally conservative. `WARN` means **inspect this evidence**, not **the root cause is proven**. Raw command output remains above the summary.

## Collection files

```bash
ror collect baseline
ror collect performance
ror collect nfs nfs.example.com
ror collect docker
ror collect kubernetes default
```

Collection writes a timestamped text file to the current directory while also showing output on screen. Set `ROR_COLLECT_OUTPUT` to choose a specific output path.

## Safety contract

Diagnostic scripts do not restart services, install packages, alter configuration, change permissions, or intentionally mutate workloads. Ordinary connection/lookup/API-read attempts are allowed when they are the diagnostic's purpose.

Do not collect secret-bearing surfaces merely because a CLI can expose them. In particular:

- process/container environment blocks are excluded;
- Tomcat diagnostics exclude systemd `Environment`;
- Docker diagnostics do not use broad `docker inspect` environment output;
- Kubernetes diagnostics do not read Secrets or dump kubeconfig contents.
