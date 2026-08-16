# Room of Requirement

> **Always equipped for the seeker's needs.**

A portable engineering toolbox for unfamiliar systems: quick references, diagnostics, reusable scripts, templates, dotfiles, runbooks, and bootstrap helpers that can travel with you from machine to machine.

## I need to...

| Need | Go to |
|---|---|
| Quickly assess an unfamiliar host | `ror doctor` |
| Capture a general-purpose handoff bundle | `ror collect baseline` |
| Remember a command or concept | [`cheat-sheets/`](cheat-sheets/README.md) |
| Copy/paste a reusable fragment | [`snippets/`](snippets/README.md) |
| Collect targeted troubleshooting evidence | [`scripts/diagnostics/`](scripts/diagnostics/README.md) |
| Run a complete utility | [`scripts/`](scripts/) |
| Follow a safe troubleshooting procedure | [`docs/runbooks/`](docs/runbooks/README.md) |
| Create something from a known-good starting point | [`templates/`](templates/README.md) |
| Configure my shell/tools | [`dotfiles/`](dotfiles/) |
| Set up ROR on a new machine | [`bootstrap/`](bootstrap/) |
| Keep machine-specific state | [`local/`](local/README.md) |

## The `ror` command

`bin/ror` is the front door to the repository.

### First look at a machine

```bash
ror doctor
ror doctor --install-suggestions
ror collect baseline
```

`ror doctor` summarizes platform/tooling information and highlights common host-health signals such as root-filesystem pressure, Linux memory pressure, failed systemd units, time synchronization, firewall/MAC visibility, proxy presence, and reboot status.

`ror collect baseline` creates a timestamped, read-only intake report combining system, network, storage, resolver, security, time-sync, service, journal, kernel-package, and reboot context. It avoids dumping process environments and reports only the presence of proxy variables rather than their values.

### Discover

```bash
ror info
ror path cheat-sheets
ror find ssh
ror find --type runbook certificate
ror search java
ror cheat subnetting
```

### Diagnose and collect

```bash
ror diagnose baseline
ror diagnose system
ror diagnose network
ror diagnose systemd sshd
ror diagnose ssh
ror diagnose dns example.com
ror diagnose tls example.com:443
ror diagnose storage
ror diagnose java 12345
ror diagnose tomcat tomcat
```

Save the same diagnostic output as a timestamped handoff file:

```bash
ror collect baseline
ror collect system
ror collect systemd sshd
ror collect tls example.com:443
```

Diagnostics are read-only by contract. Collection files are written to the current directory unless `ROR_COLLECT_OUTPUT` is set.

### Reuse

```bash
ror new ansible/playbook.yml ./playbook.yml
ror new docker/compose.yaml ./compose.yaml
ror new systemd/service.service ./myapp.service
ror new systemd/timer.timer ./myapp.timer
```

`ror new` refuses to overwrite an existing destination.

### Portable tool bundles

```bash
ror pkg list
ror pkg suggest troubleshooting
ror pkg suggest networking
ror pkg install troubleshooting
```

`pkg suggest` is read-only. `pkg install` is an explicit mutating action and translates common tool names across supported package managers where required. Package installation works from a root shell directly or through `sudo` when needed.

### Repository maintenance

```bash
ror dotfiles status
ror update
```

`ror update` refuses to pull when the ROR working tree is dirty and uses fast-forward-only Git updates.

## Bootstrap on Linux/macOS/WSL

```bash
git clone <this-repository>
cd room-of-requirement
bash bootstrap/install.sh
ror doctor --install-suggestions
```

## Bootstrap on Windows

Run from PowerShell after cloning:

```powershell
.\bootstrap\install.ps1
```

The current Windows wrapper uses Bash (for example Git Bash or WSL) to run the shared `ror` implementation.

## Current diagnostic targets

| Target | Purpose |
|---|---|
| `baseline` | General-purpose read-only host intake/handoff bundle |
| `system` | OS, kernel, uptime, CPU, memory, failed services, core state |
| `network` | addresses, routes, DNS config, listeners, basic network state |
| `systemd` | service status, unit definition, process and recent journal |
| `ssh` | sshd state, listeners, effective authentication/crypto config, logs |
| `tls` | remote handshake, leaf certificate, SANs and verification result |
| `dns` | resolver config/status and optional name lookup |
| `storage` | block devices, filesystems, inodes, mounts, LVM, large paths, open-deleted files |
| `java` | Java runtime/process/JVM metadata without dumping environments |
| `tomcat` | service/process/listener/log context for Tomcat |

## Trust and validation

Changes on `main` are guarded by GitHub Actions checks for:

- Bash syntax and error-level ShellCheck findings
- YAML and JSON validation
- local Markdown-link validation
- PowerShell parsing
- ROR CLI smoke tests on Linux and Windows runners
- full-history secret scanning

The local smoke suite can also be run manually:

```bash
bash tests/smoke/ror-smoke.sh
python3 tests/validate_markdown_links.py
```

See [`tests/`](tests/README.md) for the validation contract.

## Design principles

- **Portable:** resources should not depend on the machine where they were authored.
- **Safe:** diagnostics and discovery are read-only by default.
- **OS-aware:** platform-specific behavior belongs behind common interfaces.
- **Local stays local:** secrets and machine-specific state belong under `local/`, never Git.
- **Discoverable:** `ror find` should locate useful material across resource types.
- **Reusable:** capture procedures and patterns once rather than reconstructing them during every incident.
- **Trustworthy:** automated validation should catch portability, syntax, link, and secret-leak regressions before they become normal tooling.

See [Philosophy](docs/philosophy.md) and [Architecture](docs/architecture.md) for the repository contracts and design model.

## Quick links

- [Cheat Sheets](cheat-sheets/README.md)
- [Snippets](snippets/README.md)
- [Diagnostics](scripts/diagnostics/README.md)
- [Runbooks](docs/runbooks/README.md)
- [Templates](templates/README.md)
- [Tests](tests/README.md)
- [Architecture](docs/architecture.md)
- [Philosophy](docs/philosophy.md)
- [Changelog](CHANGELOG.md)
- [Local-state policy](local/README.md)
