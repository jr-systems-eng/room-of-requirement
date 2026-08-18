# Room of Requirement

> **Always equipped for the seeker's needs.**

A portable engineering toolbox for unfamiliar systems: quick references, diagnostics, operational utilities, reusable scripts, templates, managed dotfiles, runbooks, and bootstrap helpers that can travel from machine to machine.

## I need to...

| Need | Go to |
|---|---|
| Bring together everything ROR knows about a topic | `ror need ssh` |
| Quickly assess an unfamiliar host | `ror doctor` |
| Capture a general-purpose handoff bundle | `ror collect baseline` |
| Investigate load/memory pressure | `ror need performance` |
| Inspect NFS state / configuration guidance | `ror need nfs` |
| Inspect Docker/Kubernetes runtime health | `ror diagnose docker` / `ror diagnose kubernetes` |
| Answer a narrow operational question | [`scripts/`](scripts/README.md) |
| Prepare an admin/jumpbox toolset | `ror pkg suggest linux-admin` |
| Review portable shell/tool config | `ror dotfiles diff all` |
| Remember a command or concept | [`cheat-sheets/`](cheat-sheets/README.md) |
| Follow a safe procedure | [`docs/runbooks/`](docs/runbooks/README.md) |
| Create from a known-good starting point | [`templates/`](templates/README.md) |
| Add a reusable resource correctly | [`docs/resource-authoring.md`](docs/resource-authoring.md) |
| Set up ROR on a new machine | [`bootstrap/`](bootstrap/README.md) |

## Ask the Room

`ror need` is the curated navigation layer over the repository.

```bash
ror need list
ror need ssh
ror need certificate
ror need nfs
ror need memory
ror need tomcat
ror need docker
ror need kubernetes
ror need terraform
ror need github
```

Phase 7 makes the output more actionable while keeping it deterministic:

```text
Room of Requirement: performance
Purpose: Linux load, CPU, memory, swap, blocked tasks, and evidence-driven performance triage.

Start here:
  ror diagnose performance

Next actions:
  ror find --type runbook load
  ror find --type runbook memory

Resources:
  ...

Related rooms:
  storage          ...
  systemd          ...
  tomcat           ...
```

Topic knowledge now lives in [`config/room/`](config/room/README.md): canonical names/aliases/descriptions/related rooms, ordered actions, and resource relationships. `lib/resources.sh` is a generic reader rather than a growing topic-specific case statement.

Aliases normalize common wording such as `certificate -> tls`, `sftp -> ssh`, `memory -> performance`, `nfs4 -> nfs`, `docker -> containers`, `k8s -> kubernetes`, `tf -> terraform`, and `actions -> github`.

`ror need` is read-only. It does not execute suggestions or perform fuzzy diagnosis. Unknown topics fall back to literal repository search.

## First look at a machine

```bash
ror doctor
ror doctor --install-suggestions
ror collect baseline
```

`ror doctor` summarizes platform/tooling and common host-health signals. `ror collect baseline` creates a timestamped, read-only intake report with system, network, storage, resolver, security, time-sync, service, journal, kernel-package, and reboot context while avoiding likely-secret process environments.

## Diagnose and collect

```bash
ror diagnose baseline
ror diagnose system
ror diagnose performance
ror diagnose network
ror diagnose nfs nfs.example.com
ror diagnose systemd sshd
ror diagnose ssh
ror diagnose dns example.com
ror diagnose tls example.com:443
ror diagnose storage
ror diagnose docker
ror diagnose kubernetes default
ror diagnose java 12345
ror diagnose tomcat tomcat
```

High-value collectors end with conservative `SUMMARY` sections. A warning means **inspect this evidence**, not **ROR has proven the root cause**. Raw evidence remains visible above the summary.

New Phase 7 collectors:

- **performance** — load/CPU context, top processes, memory/swap, vmstat, blocked tasks, optional iostat, OOM evidence;
- **NFS** — local client mounts/options, exports/server/listener state, service/kernel events, optional remote TCP/2049 test;
- **Docker** — client/daemon/context, container state, Compose projects, disk usage without environment inspection;
- **Kubernetes** — context, API reachability, nodes, namespace workloads/pods/events without reading Secrets or raw kubeconfig.

Save the same evidence with `ror collect <target>`.

## Operational utilities

Phase 7 starts filling the previously scaffold-only script areas with small reusable tools:

```bash
ror run system/port-process.sh 8443
ror run networking/cert-expiry.sh example.com:443 30
ror run git/repo-health.sh .
ror run kubernetes/workload-summary.sh default
```

These are deliberately narrower than diagnostics:

- `port-process.sh` maps a local TCP/UDP port to available listener/process evidence;
- `cert-expiry.sh` shows leaf identity/dates and returns exit `2` when expired/inside the requested warning window;
- `repo-health.sh` reports branch/worktree/upstream/ahead-behind state without printing remote URLs that could embed credentials;
- `workload-summary.sh` gives a compact namespace workload/pod summary without reading Secrets.

See [Scripts](scripts/README.md).

## Discover directly

```bash
ror info
ror path cheat-sheets
ror path room
ror find ssh
ror find --type runbook certificate
ror find --type script port
ror search java
ror cheat subnetting
```

Use `ror need` for curated relationships and `ror find` for literal search.

## Runbooks

The library covers NFS configuration, LVM/filesystem growth, systemd/SSH/TLS/DNS/Tomcat troubleshooting, full filesystems, network connectivity, Java PKIX, high load, and memory pressure/OOM investigation.

```bash
ror find --type runbook nfs
ror find --type runbook lvm
ror find --type runbook dns
ror find --type runbook tomcat
ror find --type runbook memory
```

See [Runbooks](docs/runbooks/README.md).

## Reuse/templates

```bash
ror new ansible/rolling-change.yml ./rolling-change.yml
ror new ansible/inventory.ini ./inventory.ini
ror new docker/Dockerfile ./Dockerfile
ror new k8s/ingress.yaml ./ingress.yaml
ror new terraform/module.tf ./main.tf
ror new github/workflow-shellcheck.yml ./.github/workflows/shellcheck.yml
```

Template families include Ansible, Bash, Docker/Compose, Kubernetes, GitHub Actions/PR review, Terraform, logrotate, and systemd. `ror new` copies one file, refuses overwrite, and does not substitute placeholders yet; replace every `__TOKEN__` before use.

## Portable environment setup

### Package profiles

```bash
ror pkg list
ror pkg suggest linux-admin
ror pkg install linux-admin
```

Profiles: `minimal`, `troubleshooting`, `networking`, `linux-admin`, `development`, `ansible`, `containers`, `kubernetes`, and `cloud`.

`pkg suggest` is read-only. `pkg install` is explicit/mutating. Vendor/platform-specific tools are reported rather than silently installed through guessed procedures.

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

ROR installs managed fragments under `~/.config/ror/` and small marked include/source blocks instead of replacing whole configuration files. Every install creates a rollback snapshot. Git identity, credentials, SSH keys/config, and machine-specific private settings stay outside automatic management.

See [Dotfiles](dotfiles/README.md) and [Portable Workstation Setup](docs/setup/portable-workstation.md).

## Bootstrap

Safe default on Linux/macOS/WSL:

```bash
git clone <this-repository>
cd room-of-requirement
bash bootstrap/install.sh
```

Windows uses `bootstrap/install.ps1` with an available Bash environment such as Git Bash or WSL. Plain bootstrap never silently installs packages or dotfiles.

## Current diagnostic targets

| Target | Purpose |
|---|---|
| `baseline` | broad read-only host intake/handoff |
| `system` | OS, kernel, uptime, CPU, memory, failed services |
| `performance` | load, CPU/process, memory/swap, D-state, I/O/OOM evidence |
| `network` | addresses, routes, resolver state, listeners |
| `nfs` | NFS mounts/exports/server/listener/events plus optional server reachability |
| `systemd` | service/unit/process/journal state and summary |
| `ssh` | sshd listener/config/auth/crypto/log patterns |
| `tls` | handshake, certificate names/expiry/verification |
| `dns` | resolver config/status and lookup summary |
| `storage` | devices, filesystems, inodes, mounts, LVM, large/open-deleted paths |
| `docker` | Docker daemon/context/container/Compose/disk state without environment dumps |
| `kubernetes` | context/API/node/pod/workload state without Secrets/raw kubeconfig |
| `java` | Java runtime/process/JVM metadata without process environment dumps |
| `tomcat` | service/process/log context plus selected Java/Tomcat failure patterns |

## Trust and validation

`main` is guarded by GitHub Actions checks for Bash/ShellCheck, YAML/JSON, PowerShell, local Markdown links, Linux/Windows CLI smoke tests, dotfile lifecycle tests, full-history Gitleaks, and the new Room metadata validator.

Room validation checks alias uniqueness, related-room references, action/resource ownership, path safety/existence, duplicates, and minimum per-topic coverage. This means the content graph can grow without silently accumulating broken relationships.

Run locally:

```bash
bash tests/smoke/ror-smoke.sh
bash tests/smoke/dotfiles-smoke.sh
python3 tests/validate_room_metadata.py
python3 tests/validate_markdown_links.py
```

See [Tests](tests/README.md) and [Resource Authoring Guide](docs/resource-authoring.md).

## Design principles

- **Portable:** resources should not depend on the machine where they were authored.
- **Safe:** discovery/diagnostics are read-only; mutations are explicit/reversible where practical.
- **OS-aware:** platform-specific behavior belongs behind common interfaces.
- **Local stays local:** secrets and machine-specific settings are not committed.
- **Discoverable:** `ror need` provides curated relationships; `ror find` provides literal search.
- **Inspectable:** interpretation sits beside raw evidence.
- **Deterministic:** Room relationships are versioned metadata, not hidden inference.
- **Reusable:** capture procedures/tools/starting points once rather than rebuilding them each incident/project.
- **Trustworthy:** automated validation catches syntax, link, metadata, rollback, portability, and secret-leak regressions.

See [Philosophy](docs/philosophy.md), [Architecture](docs/architecture.md), and [Resource Authoring Guide](docs/resource-authoring.md).

## Quick links

- [Cheat Sheets](cheat-sheets/README.md)
- [Snippets](snippets/README.md)
- [Scripts](scripts/README.md)
- [Diagnostics](scripts/diagnostics/README.md)
- [Runbooks](docs/runbooks/README.md)
- [Templates](templates/README.md)
- [Room Metadata](config/room/README.md)
- [Resource Authoring](docs/resource-authoring.md)
- [Dotfiles](dotfiles/README.md)
- [Portable Workstation Setup](docs/setup/portable-workstation.md)
- [Bootstrap](bootstrap/README.md)
- [Tests](tests/README.md)
- [Architecture](docs/architecture.md)
- [Philosophy](docs/philosophy.md)
- [Changelog](CHANGELOG.md)
- [Local-state policy](local/README.md)
