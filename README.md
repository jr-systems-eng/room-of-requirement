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
| Follow a safe procedure | [`docs/runbooks/`](docs/runbooks/README.md) |
| Create from a known-good starting point | [`templates/`](templates/README.md) |
| Add a new reusable resource correctly | [`docs/resource-authoring.md`](docs/resource-authoring.md) |
| Set up a portable workstation/jumpbox | [`docs/setup/portable-workstation.md`](docs/setup/portable-workstation.md) |
| Set up ROR on a new machine | [`bootstrap/`](bootstrap/README.md) |

## The `ror` command

`bin/ror` is the front door to the repository.

### Ask the Room

`ror need` provides a curated view of related resources so you do not have to remember which directory contains them.

```bash
ror need list
ror need ssh
ror need certificate
ror need nfs
ror need performance
ror need tomcat
ror need kubernetes
ror need terraform
ror need github
```

Curated topics show a purpose, recommended first commands, and related references, diagnostics, runbooks, snippets, templates, guides, or managed configuration. Aliases normalize common wording such as `certificate` -> `tls`, `sftp` -> `ssh`, `memory` -> `performance`, `nfs4` -> `nfs`, `k8s` -> `kubernetes`, and `tf` -> `terraform`.

The relationship map is deterministic in `lib/resources.sh`; `ror need` does not use fuzzy diagnosis. Unknown topics fall back to normal repository search.

### First look at a machine

```bash
ror doctor
ror doctor --install-suggestions
ror collect baseline
```

`ror doctor` summarizes platform/tooling and common host-health signals. `ror collect baseline` creates a timestamped, read-only intake report with system, network, storage, resolver, security, time-sync, service, journal, kernel-package, and reboot context while avoiding likely-secret process environments.

### Discover

```bash
ror info
ror path cheat-sheets
ror find ssh
ror find --type runbook certificate
ror search java
ror cheat subnetting
```

Use `ror need` for a curated problem view; use `ror find` for literal repository search.

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

High-value targeted collectors end with conservative `SUMMARY` sections. A warning means **inspect this evidence**, not **ROR has proven the root cause**. Raw evidence remains visible above the summary.

Save the same output as a handoff file with `ror collect <target>`. Diagnostics are read-only by contract.

## Runbooks

The runbook library now covers both administration and troubleshooting. Examples:

```bash
ror need nfs
ror find --type runbook lvm
ror find --type runbook dns
ror find --type runbook tomcat
ror find --type runbook load
ror find --type runbook memory
```

Current high-value procedures include NFS configuration, LVM/filesystem growth, systemd/SSH/TLS/DNS/Tomcat troubleshooting, full filesystems, network connectivity, Java PKIX, high load, and memory pressure/OOM investigation.

See [Runbooks](docs/runbooks/README.md).

## Reuse/templates

Phase 6 substantially expands the copy-based asset library.

```bash
ror new ansible/rolling-change.yml ./rolling-change.yml
ror new ansible/inventory.ini ./inventory.ini
ror new docker/Dockerfile ./Dockerfile
ror new k8s/ingress.yaml ./ingress.yaml
ror new k8s/persistent-volume-claim.yaml ./pvc.yaml
ror new terraform/module.tf ./main.tf
ror new github/workflow-shellcheck.yml ./.github/workflows/shellcheck.yml
```

Template families now include Ansible, Bash, Docker/Compose, Kubernetes, GitHub Actions/PR review, Terraform, logrotate, and systemd. `ror new` copies one file, refuses overwrite, and does not substitute placeholders yet; replace every `__TOKEN__` before use.

See [Templates](templates/README.md).

## Portable environment setup

### Package profiles

```bash
ror pkg list
ror pkg suggest linux-admin
ror pkg install linux-admin
```

Profiles: `minimal`, `troubleshooting`, `networking`, `linux-admin`, `development`, `ansible`, `containers`, `kubernetes`, and `cloud`.

`pkg suggest` is read-only. `pkg install` is explicit and mutating. Vendor/platform-specific tools are reported separately rather than silently installed through guessed procedures.

### Managed dotfiles

```bash
ror dotfiles status
ror dotfiles diff all
ror dotfiles install bash
ror dotfiles install git
ror dotfiles install tmux
ror dotfiles backups
ror dotfiles restore latest
```

ROR installs managed fragments under `~/.config/ror/` and adds small marked include/source blocks instead of replacing whole configuration files. Every install creates a rollback snapshot first. Git identity, credentials, SSH keys/config, and machine-specific private settings remain outside automatic management.

See [Dotfiles](dotfiles/README.md) and [Portable Workstation Setup](docs/setup/portable-workstation.md).

## Bootstrap

Safe default on Linux/macOS/WSL:

```bash
git clone <this-repository>
cd room-of-requirement
bash bootstrap/install.sh
```

Explicit workstation setup can add requested profiles/dotfiles. Windows uses `bootstrap/install.ps1` and an available Bash environment such as Git Bash or WSL. Plain bootstrap never silently installs packages or dotfiles.

## Current diagnostic targets

| Target | Purpose |
|---|---|
| `baseline` | General-purpose read-only host intake/handoff bundle |
| `system` | OS, kernel, uptime, CPU, memory, failed services, core state |
| `network` | addresses, routes, DNS config, listeners, basic network state |
| `systemd` | service status, unit definition, process, journal, observed-state summary |
| `ssh` | sshd state, listener/config validation, auth/crypto config, high-signal log patterns |
| `tls` | remote handshake, certificate names/expiry, chain verification, summary |
| `dns` | resolver config/status, optional lookup, DNS response summary |
| `storage` | devices, filesystems, inodes, mounts, LVM, large paths, open-deleted files, pressure summary |
| `java` | Java runtime/process/JVM metadata without dumping environments |
| `tomcat` | service/process/log context plus selected Java/Tomcat failure patterns |

## Trust and validation

Changes on `main` are guarded by GitHub Actions checks for Bash syntax/ShellCheck errors, YAML/JSON, local Markdown links, PowerShell parsing, Linux/Windows CLI smoke tests, dotfile lifecycle tests, and full-history secret scanning.

Phase 6 adds relationship-integrity coverage: every path declared by `ror need` must exist, and representative new Ansible/Kubernetes/Terraform templates must copy successfully with `ror new`.

Run locally:

```bash
bash tests/smoke/ror-smoke.sh
bash tests/smoke/dotfiles-smoke.sh
python3 tests/validate_markdown_links.py
```

See [Tests](tests/README.md) and [Resource Authoring Guide](docs/resource-authoring.md).

## Design principles

- **Portable:** resources should not depend on the machine where they were authored.
- **Safe:** diagnostics/discovery are read-only by default; mutations are explicit and reversible where practical.
- **OS-aware:** platform-specific behavior belongs behind common interfaces.
- **Local stays local:** secrets and machine-specific settings are not committed.
- **Discoverable:** `ror need` provides curated relationships while `ror find` provides literal search.
- **Inspectable:** interpretation sits beside raw evidence.
- **Reusable:** capture procedures and starting points once rather than rebuilding them during every incident/project.
- **Trustworthy:** automated validation should catch portability, syntax, link, relationship, rollback, and secret-leak regressions.

See [Philosophy](docs/philosophy.md), [Architecture](docs/architecture.md), and [Resource Authoring Guide](docs/resource-authoring.md).

## Quick links

- [Cheat Sheets](cheat-sheets/README.md)
- [Snippets](snippets/README.md)
- [Diagnostics](scripts/diagnostics/README.md)
- [Runbooks](docs/runbooks/README.md)
- [Templates](templates/README.md)
- [Resource Authoring](docs/resource-authoring.md)
- [Dotfiles](dotfiles/README.md)
- [Portable Workstation Setup](docs/setup/portable-workstation.md)
- [Bootstrap](bootstrap/README.md)
- [Tests](tests/README.md)
- [Architecture](docs/architecture.md)
- [Philosophy](docs/philosophy.md)
- [Changelog](CHANGELOG.md)
- [Local-state policy](local/README.md)
