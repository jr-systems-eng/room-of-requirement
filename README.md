# Room of Requirement

> **Always equipped for the seeker's needs.**

A portable engineering toolbox for unfamiliar systems: quick references, diagnostics, guided workflows, operational utilities, reusable scripts, templates, managed dotfiles, runbooks, and bootstrap helpers that can travel from machine to machine.

## I need to...

| Need | Go to |
|---|---|
| Bring together everything ROR knows about a topic | `ror need ssh` |
| Quickly assess an unfamiliar host | `ror doctor` |
| Capture a general-purpose handoff bundle | `ror collect baseline` |
| Follow an inspectable procedure before changing a host | `ror workflow list` |
| Investigate load/memory pressure | `ror need performance` |
| Inspect or configure an NFS client safely | `ror need nfs` / `ror workflow nfs-client ...` |
| Inspect Docker/Kubernetes runtime health | `ror diagnose docker` / `ror diagnose kubernetes` |
| Validate an Ansible inventory without connecting to hosts | `ror workflow ansible-inventory --inventory hosts.ini` |
| Prepare certificate deployment evidence | `ror workflow certificate-deploy-prep ...` |
| Answer a narrow operational question | [`scripts/`](scripts/README.md) |
| Prepare an admin/jumpbox toolset | `ror workflow workstation` |
| Review portable shell/tool config | `ror dotfiles diff all` |
| Remember a command or concept | [`cheat-sheets/`](cheat-sheets/README.md) |
| Follow a detailed manual procedure | [`docs/runbooks/`](docs/runbooks/README.md) |
| Create from a known-good starting point | [`templates/`](templates/README.md) |
| Add a reusable resource correctly | [`docs/resource-authoring.md`](docs/resource-authoring.md) |
| Check the installed ROR build | `ror version` / `ror self-test` |
| Set up ROR on a new machine | [`bootstrap/`](bootstrap/README.md) |

## The operating model

ROR now has four intentionally distinct operational layers:

```text
ror need        -> What resources relate to this problem/topic?
ror diagnose    -> What state is the system in?
ror workflow    -> What ordered procedure should I follow, and what would it change?
ror run         -> Run one specific utility.
```

The layers are complementary. A Room can point to a diagnostic, runbook, workflow, utility, template, or related Room without automatically executing any of them.

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

Example:

```text
Room of Requirement: nfs
Purpose: NFSv4 server exports, client mounts, persistence, permissions, and connectivity.

Start here:
  ror diagnose nfs [server]

Next actions:
  ror workflow nfs-client --server <server> --export /export --mountpoint /mnt/export
  ror find --type runbook nfs
  ror need network

Resources:
  ...

Related rooms:
  network          ...
  storage          ...
```

Topic knowledge lives in [`config/room/`](config/room/README.md): canonical names/aliases/descriptions/related rooms, ordered actions, and resource relationships. `lib/resources.sh` is a generic reader rather than a growing topic-specific case statement.

Aliases normalize common wording such as `certificate -> tls`, `sftp -> ssh`, `memory -> performance`, `nfs4 -> nfs`, `docker -> containers`, `k8s -> kubernetes`, `tf -> terraform`, and `actions -> github`.

`ror need` is read-only. It does not execute suggestions or perform fuzzy diagnosis. Unknown topics fall back to literal repository search.

## Guided operations

Phase 8 introduces `ror workflow` as a transparent procedure layer.

```bash
ror workflow list

ror workflow nfs-client \
  --server nfs.example.com \
  --export /data \
  --mountpoint /mnt/data

ror workflow service-recovery --service sshd
ror workflow workstation
ror workflow ansible-inventory --inventory hosts.ini
ror workflow certificate-deploy-prep --cert cert.pem --key key.pem --target /etc/pki/tls/certs/app.pem
```

Every workflow is registered under [`config/workflows/`](config/workflows/README.md) and implemented under [`workflows/`](workflows/README.md).

Workflow modes deliberately distinguish risk:

- **read-only** — inspection/validation only;
- **preparation** — builds an evidence-backed change/deployment plan but does not apply it;
- **plan-apply** — default invocation is non-mutating and requires an explicit `--apply` to perform the narrow operation described by the workflow.

All Phase 8 workflows start with status **experimental**, even when CI is green. CI proves code/metadata/test integrity; representative field testing is required before a workflow is promoted to `stable`.

### NFS client workflow

Plan only:

```bash
ror workflow nfs-client \
  --server nfs.example.com \
  --export /media \
  --mountpoint /mnt/media \
  --persist
```

The workflow checks platform/tooling, name resolution, TCP/2049 when `nc` is available, mountpoint safety, existing mounts, `/etc/fstab` conflicts, and privilege availability. It then prints the exact mount/persistence plan without changing the host.

Only after review:

```bash
ror workflow nfs-client \
  --server nfs.example.com \
  --export /media \
  --mountpoint /mnt/media \
  --persist \
  --apply
```

Persistent apply backs up `/etc/fstab` before adding a guarded NFS entry and prints rollback commands using the actual backup path.

### systemd service recovery

```bash
ror workflow service-recovery --service tomcat
```

The default path inspects unit state/status and shows the restart/validation plan. `--apply` performs only `systemctl restart <unit>` followed by state/journal validation; it never edits service configuration.

### Portable workstation

```bash
ror workflow workstation
ror workflow workstation --profile troubleshooting --dotfiles bash,git,tmux
```

The default path combines `ror pkg suggest` with managed-dotfile diffs. `--apply` delegates to the existing explicit package/dotfile mutation paths rather than reimplementing them.

### Ansible inventory validation

```bash
ror workflow ansible-inventory --inventory hosts.ini
ror workflow ansible-inventory --inventory hosts.ini --host app01
```

This workflow is fully read-only: it parses the inventory, prints the graph, and can render one host's variables without contacting managed hosts.

### Certificate deployment preparation

```bash
ror workflow certificate-deploy-prep \
  --cert fullchain.pem \
  --key privkey.pem \
  --chain chain.pem \
  --target /etc/pki/tls/certs/app.pem
```

It inspects certificate identity/dates, expiry window, certificate/key public-key match, optional chain verification, and target metadata/backup naming. It intentionally has **no apply mode**.

LVM/filesystem growth remains runbook-only in Phase 8. ROR will not automate storage expansion until the workflow framework has been field-tested more extensively.

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

Current operational collectors include:

- **performance** — load/CPU context, top processes, memory/swap, vmstat, blocked tasks, optional iostat, OOM evidence;
- **NFS** — local client mounts/options, exports/server/listener state, service/kernel events, optional remote TCP/2049 test;
- **Docker** — client/daemon/context, container state, Compose projects, disk usage without environment inspection;
- **Kubernetes** — context, API reachability, nodes, namespace workloads/pods/events without reading Secrets or raw kubeconfig.

Save the same evidence with `ror collect <target>`.

## Operational utilities

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
ror version
ror path cheat-sheets
ror path room
ror path workflows
ror find ssh
ror find --type workflow nfs
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

## Version, update, and self-test

ROR now carries an explicit repository version in `VERSION`.

```bash
ror version
ror update --check
ror self-test
```

`ror version` reports the semantic version and local Git commit/branch/worktree state. `ror update --check` compares the current branch against its configured remote branch using `git ls-remote` without updating remote-tracking refs. It never prints the remote URL. `ror self-test` is local, read-only, and network-independent: it checks core paths, Bash syntax, metadata validators when Python is available, and basic CLI/workflow dispatch.

`ror update` retains its existing safety behavior: the worktree must be clean and Git performs a fast-forward-only pull.

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

`main` is guarded by GitHub Actions checks for Bash/ShellCheck, YAML/JSON, PowerShell, local Markdown links, Linux/Windows CLI smoke tests, workflow smoke tests, external diagnostic stubs, dotfile lifecycle tests, full-history Gitleaks, Room metadata validation, and workflow metadata validation.

Workflow CI explicitly tests only non-mutating paths. `--apply` behavior requires field testing on representative systems; passing CI alone is not a reason to promote an experimental workflow to stable.

Run locally:

```bash
ror self-test
bash tests/smoke/ror-smoke.sh
bash tests/smoke/workflow-smoke.sh
bash tests/smoke/dotfiles-smoke.sh
python3 tests/validate_room_metadata.py
python3 tests/validate_workflow_metadata.py
python3 tests/validate_markdown_links.py
```

See [Tests](tests/README.md), [Workflow Metadata](config/workflows/README.md), and [Resource Authoring Guide](docs/resource-authoring.md).

## Design principles

- **Portable:** resources should not depend on the machine where they were authored.
- **Safe:** discovery/diagnostics are read-only; mutations are explicit/reversible where practical.
- **Plan before apply:** guided mutation defaults to an inspectable plan and requires an explicit apply request.
- **Field-tested:** CI is necessary but workflow maturity is earned on representative systems before promotion to stable.
- **OS-aware:** platform-specific behavior belongs behind common interfaces.
- **Local stays local:** secrets and machine-specific settings are not committed.
- **Discoverable:** `ror need` provides curated relationships; `ror find` provides literal search.
- **Inspectable:** interpretation and workflow plans sit beside the evidence that supports them.
- **Deterministic:** Room/workflow relationships are versioned metadata, not hidden inference.
- **Reusable:** capture procedures/tools/starting points once rather than rebuilding them each incident/project.
- **Trustworthy:** automated validation catches syntax, link, metadata, rollback, portability, and secret-leak regressions.

See [Philosophy](docs/philosophy.md), [Architecture](docs/architecture.md), and [Resource Authoring Guide](docs/resource-authoring.md).

## Quick links

- [Cheat Sheets](cheat-sheets/README.md)
- [Snippets](snippets/README.md)
- [Scripts](scripts/README.md)
- [Diagnostics](scripts/diagnostics/README.md)
- [Guided Workflows](workflows/README.md)
- [Workflow Metadata](config/workflows/README.md)
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
