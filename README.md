# Room of Requirement

> **Always equipped for the seeker's needs.**

A portable engineering toolbox for unfamiliar systems: quick references, diagnostics, reusable scripts, templates, managed dotfiles, runbooks, and bootstrap helpers that can travel with you from machine to machine.

## I need to...

| Need | Go to |
|---|---|
| Bring together everything ROR knows about a topic | `ror need ssh` |
| Quickly assess an unfamiliar host | `ror doctor` |
| Capture a general-purpose handoff bundle | `ror collect baseline` |
| Prepare an admin/jumpbox toolset | `ror pkg suggest linux-admin` |
| Review portable shell/tool config | `ror dotfiles diff all` |
| Remember a command or concept | [`cheat-sheets/`](cheat-sheets/README.md) |
| Copy/paste a reusable fragment | [`snippets/`](snippets/README.md) |
| Collect targeted troubleshooting evidence | [`scripts/diagnostics/`](scripts/diagnostics/README.md) |
| Follow a safe troubleshooting procedure | [`docs/runbooks/`](docs/runbooks/README.md) |
| Create something from a known-good starting point | [`templates/`](templates/README.md) |
| Set up a portable workstation/jumpbox | [`docs/setup/portable-workstation.md`](docs/setup/portable-workstation.md) |
| Set up ROR on a new machine | [`bootstrap/`](bootstrap/README.md) |
| Keep repository-local machine state | [`local/`](local/README.md) |

## The `ror` command

`bin/ror` is the front door to the repository.

### Ask the Room

`ror need` provides a curated view of the resources related to a problem instead of making you remember which directory contains them.

```bash
ror need list
ror need ssh
ror need certificate
ror need storage
ror need java
ror need kubernetes
```

For a curated topic, ROR shows:

- what the topic covers;
- recommended first commands;
- related references/cheat sheets;
- diagnostic collectors;
- troubleshooting runbooks;
- useful snippets, templates, or managed configuration when applicable.

Aliases map common wording to the same topic. For example, `certificate`, `cert`, `ssl`, and `openssl` all map to the `tls` topic; `sftp` maps to `ssh`; and `pkix`/`keystore` map to `java`.

The relationship map is deliberately deterministic and lives in `lib/resources.sh`. `ror need` does not use fuzzy inference or claim to diagnose a problem. If a topic does not have a curated map yet, it falls back to normal repository search.

### First look at a machine

```bash
ror doctor
ror doctor --install-suggestions
ror collect baseline
```

`ror doctor` summarizes platform/tooling information and highlights common host-health signals such as root-filesystem pressure, Linux memory pressure, failed systemd units, time synchronization, firewall/MAC visibility, proxy presence, reboot status, and managed-dotfile state.

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

Use `ror need` when a curated problem view is useful; use `ror find` when you want literal repository search.

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

High-value targeted collectors now end with a conservative `SUMMARY` section. These summaries report directly observable state such as service activity, config validation, listener presence, certificate verification/expiry, DNS response status, filesystem/inode pressure, Java process presence, and selected high-signal log patterns.

A warning means **inspect this evidence**, not **ROR has proven the root cause**. The full raw evidence remains above the summary so the interpretation is always inspectable.

Save the same diagnostic output as a timestamped handoff file:

```bash
ror collect baseline
ror collect systemd sshd
ror collect tls example.com:443
```

Diagnostics are read-only by contract. Collection files are written to the current directory unless `ROR_COLLECT_OUTPUT` is set.

## Portable environment setup

### Package profiles

```bash
ror pkg list
ror pkg suggest linux-admin
ror pkg install linux-admin
```

Current profiles:

| Profile | Intent |
|---|---|
| `minimal` | Git, curl, jq |
| `troubleshooting` | General host/incident troubleshooting |
| `networking` | DNS/TCP/TLS/packet/path troubleshooting |
| `linux-admin` | Broad Linux admin/jumpbox toolkit |
| `development` | Git/Python/terminal development basics |
| `ansible` | Distro-packaged Ansible control-node basics |
| `containers` | Container prerequisites/runtime where portable |
| `kubernetes` | Common prerequisites; kubectl/helm reported separately |
| `cloud` | Common prerequisites; gcloud/govc reported separately |

`pkg suggest` is read-only. `pkg install` is explicit and mutating. Package names are translated where needed (for example `dig` -> `bind-utils` on DNF systems and `dnsutils` on APT systems).

Vendor/platform-specific tools that cannot be installed portably are reported separately rather than silently guessed.

### Managed dotfiles

Review first:

```bash
ror dotfiles status
ror dotfiles diff all
ror dotfiles diff bash
```

Install explicitly:

```bash
ror dotfiles install bash
ror dotfiles install git
ror dotfiles install tmux
ror dotfiles install all
```

ROR does **not** replace entire existing config files. It installs managed fragments under `~/.config/ror/` and adds small marked include/source blocks to the host's Bash/Readline/Git/tmux/PowerShell configuration.

Every install creates a rollback snapshot first:

```bash
ror dotfiles backups
ror dotfiles restore latest
ror dotfiles restore <backup-id>
```

Git identity, credentials, SSH keys/config, and machine-specific private settings are intentionally not managed automatically.

See [Dotfiles](dotfiles/README.md) and [Portable Workstation Setup](docs/setup/portable-workstation.md).

## Reuse

```bash
ror new ansible/playbook.yml ./playbook.yml
ror new docker/compose.yaml ./compose.yaml
ror new systemd/service.service ./myapp.service
ror new systemd/timer.timer ./myapp.timer
```

`ror new` refuses to overwrite an existing destination.

## Bootstrap

### Linux/macOS/WSL

Safe default:

```bash
git clone <this-repository>
cd room-of-requirement
bash bootstrap/install.sh
```

Explicit workstation setup can be combined when desired:

```bash
bash bootstrap/install.sh \
  --profile linux-admin \
  --dotfiles bash \
  --dotfiles git \
  --dotfiles tmux
```

### Windows

From PowerShell after cloning:

```powershell
.\bootstrap\install.ps1
```

Or explicitly request setup:

```powershell
.\bootstrap\install.ps1 -PackageProfile linux-admin -Dotfiles bash,git
```

The Windows wrapper uses an available Bash environment such as Git Bash or WSL for the shared ROR CLI.

Plain bootstrap never silently installs packages or dotfiles.

## Current diagnostic targets

| Target | Purpose |
|---|---|
| `baseline` | General-purpose read-only host intake/handoff bundle |
| `system` | OS, kernel, uptime, CPU, memory, failed services, core state |
| `network` | addresses, routes, DNS config, listeners, basic network state |
| `systemd` | service status, unit definition, process, recent journal, observed-state summary |
| `ssh` | sshd state, listener/config validation, auth/crypto config, high-signal log patterns |
| `tls` | remote handshake, certificate names/expiry, chain verification, observed-state summary |
| `dns` | resolver config/status, optional lookup, DNS response summary |
| `storage` | block devices, filesystems, inodes, mounts, LVM, large paths, open-deleted files, pressure summary |
| `java` | Java runtime/process/JVM metadata and process-presence summary without dumping environments |
| `tomcat` | service/process/log context plus selected Java/Tomcat failure patterns |

## Trust and validation

Changes on `main` are guarded by GitHub Actions checks for:

- Bash syntax and error-level ShellCheck findings
- YAML and JSON validation
- local Markdown-link validation
- PowerShell parsing
- ROR CLI smoke tests on Linux and Windows runners
- curated `ror need` topic/resource behavior
- diagnostic `SUMMARY` presence for portable smoke-test targets
- isolated dotfile install/restore lifecycle tests on Linux and Windows runners
- full-history secret scanning

The local smoke suite can also be run manually:

```bash
bash tests/smoke/ror-smoke.sh
bash tests/smoke/dotfiles-smoke.sh
python3 tests/validate_markdown_links.py
```

See [`tests/`](tests/README.md) for the validation contract.

## Design principles

- **Portable:** resources should not depend on the machine where they were authored.
- **Safe:** diagnostics/discovery are read-only by default; mutations are explicit and reversible where practical.
- **OS-aware:** platform-specific behavior belongs behind common interfaces.
- **Local stays local:** secrets and machine-specific settings are not committed.
- **Discoverable:** `ror need` provides curated relationships while `ror find` provides literal search.
- **Inspectable:** diagnostic interpretation sits beside the raw evidence and never hides how a conclusion was reached.
- **Reusable:** capture procedures and patterns once rather than reconstructing them during every incident.
- **Trustworthy:** automated validation should catch portability, syntax, link, rollback, and secret-leak regressions before they become normal tooling.

See [Philosophy](docs/philosophy.md) and [Architecture](docs/architecture.md) for the repository contracts and design model.

## Quick links

- [Cheat Sheets](cheat-sheets/README.md)
- [Snippets](snippets/README.md)
- [Diagnostics](scripts/diagnostics/README.md)
- [Runbooks](docs/runbooks/README.md)
- [Templates](templates/README.md)
- [Dotfiles](dotfiles/README.md)
- [Portable Workstation Setup](docs/setup/portable-workstation.md)
- [Bootstrap](bootstrap/README.md)
- [Tests](tests/README.md)
- [Architecture](docs/architecture.md)
- [Philosophy](docs/philosophy.md)
- [Changelog](CHANGELOG.md)
- [Local-state policy](local/README.md)
