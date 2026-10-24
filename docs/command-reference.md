# Room of Requirement — Command and Feature Reference

This reference describes commands implemented in `bin/ror` and resources present in the current repository. For decisions and beginner walkthroughs see [User Guide](user-guide.md); for end-to-end situations see [Operational Recipes](operational-recipes.md).

## CLI invocation

All examples assume the `ror` wrapper is available in `PATH`. Otherwise, from the repository root run `bash bin/ror ...`. The shared CLI is Bash; PowerShell bootstrap supplies a Windows wrapper.

### Discovery commands

| Command | Inputs | Behavior / result |
| --- | --- | --- |
| `ror help` or `ror --help` | None | Print CLI overview |
| `ror doctor [--install-suggestions]` | Optional flag | Read-only host/tool/dotfiles summary; optional package suggestions |
| `ror info` | None | Show ROR version, home path, OS/architecture, manager and metadata/dotfile locations |
| `ror version` | None | Show `VERSION` plus local Git commit/branch/worktree state |
| `ror path [NAME]` | Optional path alias | Print a path, default repository root |
| `ror need [TOPIC\|list]` | Canonical name or alias | Display curated room actions, resources and related rooms; list names if missing argument |
| `ror find [--type TYPE] TERM` | Literal term | Search names and content in supported repository categories |
| `ror search ...` | Same as `find` | Alias |
| `ror cheat TERM` | Term | Print sole matching cheat sheet using `PAGER` (or `cat`); list filenames when multiple match |
| `ror cheatsheet TERM` | Term | Alias |

`ror find` type values: `all`, `cheat`/`cheats`/`cheat-sheet`/`cheat-sheets`, `snippet`/`snippets`, `diagnostic`/`diagnostics`, `script`/`scripts`, `workflow`/`workflows`, `runbook`/`runbooks`, `doc`/`docs`, `template`/`templates`. It uses literal case-insensitive pathname/content search, not semantic AI search.

`ror path` recognizes `home`/`root`, `cheat-sheets`, `snippets`, `scripts`, `templates`, `docs`, `room`/`metadata`, `workflow`/`workflows`, `workflow-metadata` and `local`, plus singular aliases shown in `bin/ror`. `ror path workflows` points to executable workflow scripts; `ror path workflow-metadata` points to the registry.

### Curated Room topics

| Room | Examples of aliases | Begin with |
| --- | --- | --- |
| `ssh` | `sshd`, `sftp` | `ror need ssh` |
| `tls` | `ssl`, `cert`, `certificate`, `openssl` | `ror need tls` |
| `dns` | `resolver`, `resolution` | `ror need dns` |
| `network` | `networking`, `connectivity`, `routing` | `ror need network` |
| `systemd` | `systemctl`, `service`, `journal` | `ror need systemd` |
| `storage` | `disk`, `filesystem`, `lvm` | `ror need storage` |
| `nfs` | `nfs4`, `nfsv4` | `ror need nfs` |
| `performance` | `perf`, `load`, `memory`, `swap` | `ror need performance` |
| `java` | `jvm`, `pkix`, `truststore`, `keystore` | `ror need java` |
| `tomcat` | `catalina` | `ror need tomcat` |
| `kubernetes` | `k8s`, `kubectl` | `ror need kubernetes` |
| `ansible` | — | `ror need ansible` |
| `containers` | `docker`, `compose`, `podman` | `ror need containers` |
| `terraform` | `tf`, `iac` | `ror need terraform` |
| `github` | `gha`, `actions`, `workflows` | `ror need github` |
| `git` | — | `ror need git` |
| `agents` | `agent` | `ror need agents` |

The canonical, current source of topic names, descriptions and aliases is [Room topics](../config/room/topics.tsv); related actions and resource paths are in [Room Metadata](../config/room/README.md). The first action becomes **Start here**; suggestions are not automatically executed.

## Diagnostics and collection

```bash
ror diagnose TARGET [args...]
ror diag TARGET [args...]                  # alias
ror collect TARGET [args...]               # terminal + timestamped .txt
ROR_COLLECT_OUTPUT=./report.txt ror collect TARGET [args...]
```

| Target | Arguments | Evidence captured / purpose |
| --- | --- | --- |
| `baseline` (alias `intake`) | None | Broad intake: system/network/storage/DNS/security/firewall/time/services/journal/kernel/reboot; excludes expensive top-level disk scan |
| `system` | None | Host, kernel, distro, uptime, CPU/memory, storage, network, failed services/time |
| `network` | None | Interfaces, routing, neighbors, listeners, DNS, basic reachability checks |
| `systemd` (alias `service`) | **Required:** service name | Status, unit, non-secret properties, journal, failed units and summary |
| `ssh` (alias `sshd`) | Optional service name; default `sshd` | SSH version/service/listener/config validation/auth and KEX log patterns |
| `tls` (aliases `ssl`, `certificate`, `cert`) | **Required:** `host[:port]`; default port 443 | TLS handshake, certificate metadata, SANs, verification, expiry/name summary |
| `dns` | Optional hostname | Resolver configuration/hosts file, DNS queries, response interpretation |
| `storage` (aliases `disk`, `filesystem`, `fs`) | None | Devices, mounts, capacity/inodes, LVM, top-level directory usage, deleted-open files |
| `nfs` (aliases `nfs4`, `nfsv4`) | Optional server hostname | NFS client mounts, exports/listeners/service state and remote TCP/2049 test |
| `performance` (aliases `perf`, `load`, `memory`) | None | CPU/load, memory/swap, blocked tasks, I/O and OOM evidence |
| `docker` (aliases `container`, `containers`) | None | Docker context/daemon, container and Compose state, disk usage without env dump |
| `kubernetes` (alias `k8s`) | Optional namespace; current or default when absent | Current context, API, nodes, workloads, pods/events; no Secrets/raw kubeconfig |
| `java` (alias `jvm`) | Optional PID | Java runtime/processes and requested PID/JDK diagnostics |
| `tomcat` | Optional service name; default `tomcat` | Tomcat service/process/log context with selected JVM/PKIX/bind patterns |

All targets dispatch scripts under [Diagnostic Index](../scripts/diagnostics/README.md). The `SUMMARY` lines are conservative. Optional tools may be missing; a successful command can still contain a warning worth investigating. `ror collect` writes a filename in the invoking directory unless `ROR_COLLECT_OUTPUT` is set; it preserves the collector exit status.

## Guided workflows: exact options

To discover status/mode use `ror workflow list`. Each script also accepts `--help`. The currently registered [workflows](../config/workflows/index.tsv) are **experimental**.

| Workflow | Mode | Syntax / notable options | Change boundary |
| --- | --- | --- | --- |
| `nfs-client` | plan-apply | `--server HOST --export /PATH --mountpoint /PATH [--options OPTS] [--persist] [--apply]` | Default `--options vers=4`; `--persist` guards and backs up fstab; apply mounts and optionally configures persistence |
| `service-recovery` | plan-apply | `--service NAME [--apply]` | Apply restarts one unit and checks status/journal, never edits unit config |
| `workstation` | plan-apply | `[--profile PROFILE] [--dotfiles GROUP1,GROUP2\|none] [--apply]` | Defaults `linux-admin` + `bash,git,tmux`; apply delegates to explicit package/dotfile installers |
| `ansible-inventory` | read-only | `--inventory PATH [--host HOST]`, `-i` alias | Parses inventory, prints graph and optional host vars, no remote host connections |
| `certificate-deploy-prep` | preparation | `--cert CERT.pem --key KEY.pem [--chain CHAIN.pem] [--target PATH] [--days N]` | Default expiry window 30 days; no deployment and `--apply` is explicitly rejected |

A `plan-apply` command without `--apply` prints preflight and the plan even if it reports blocking findings; an actual apply refuses those blockers. Never equate successful CI with field-tested apply behavior. To increase safety, inspect the target state yourself first and store collection evidence before any change.

## Direct operational utilities

`ror run SCRIPT [args...]` accepts a path relative to `scripts/`, with optional `scripts/` prefix. It dispatches `.sh` with Bash, `.py` with Python 3 and `.ps1` with `pwsh`. Review scripts before invoking: unlike the diagnostic dispatcher, `ror run` does not enforce a read-only contract.

| Utility | Exact input | Useful result |
| --- | --- | --- |
| `system/port-process.sh` | `PORT` (1–65535) | `ss` and optional `lsof` evidence of local TCP/UDP listener/process ownership |
| `networking/cert-expiry.sh` | `HOST[:PORT] [WARNING_DAYS]` | Leaf identity/dates; defaults port 443 and warning 30 days; exit `2` for within-window/expired |
| `git/repo-health.sh` | `[DIRECTORY]` (default current dir) | Git root/branch/upstream, local changes, ahead/behind; omits remote URLs |
| `git/audit-agent-standards.sh` | `[--root DIR] [--exclude names,comma,separated] [--strict]` | One row per immediate child Git worktree with root `AGENTS.md` state; strict fails on missing/untracked/modified/placeholders |
| `kubernetes/workload-summary.sh` | `[NAMESPACE]` | Deployments/StatefulSets/DaemonSets, pods, restart/problem count in current context |

Strict agent-audit status labels: `MISSING`, `LOCAL_ONLY`, `MODIFIED`, `TRACKED` and optional `+PLACEHOLDERS`. `--strict` returns 1 when any included repository is not cleanly tracked. No command in that utility writes to sibling repos.

## Reusable content

| Category | Where to find | How to consume |
| --- | --- | --- |
| Cheat sheets | [Index](../cheat-sheets/README.md) | `ror cheat TERM` or read Markdown |
| Snippets | [Index](../snippets/README.md) | Copy only the command you need and substitute examples |
| Runbooks | [Index](runbooks/README.md) | Follow the manual preflight, decision, validation, rollback procedure |
| Templates | [Index](../templates/README.md) | `ror new FAMILY/FILE DESTINATION`; then resolve every `__TOKEN__` |
| Agent templates | [Kit](../templates/agents/README.md) | Copy root instructions, scoped work order or handoff; then adapt to target repo |
| Room registry | [Metadata](../config/room/README.md) | Maintain topics/actions/resources TSVs; validate before committing |
| Workflow registry | [Metadata](../config/workflows/README.md) | Maintain name/mode/status/script mapping and metadata tests |

`ror new` creates destination directories if needed, but **refuses any existing destination**. It does not process a template directory or substitute tokens.

## Workstation and maintenance commands

| Command | Side effects | Purpose |
| --- | --- | --- |
| `ror pkg list` | None | Show profiles |
| `ror pkg suggest PROFILE` | None | List missing package-managed and external tools plus suggested manager command |
| `ror pkg install PROFILE` | **Installs packages** | Install missing manager-supported items; external tools remain manual |
| `ror dotfiles status` | None | Show managed fragment/integration state |
| `ror dotfiles diff [GROUP\|all]` | None | Review proposed managed config changes |
| `ror dotfiles install GROUP\|all` | **Edits user configuration** | Install managed fragments and marked host include blocks; creates backup snapshot |
| `ror dotfiles backups` | None | List rollback snapshots |
| `ror dotfiles restore [latest\|ID]` | **Restores/removes managed files** | Return files to their pre-install snapshot for selected transaction |
| `ror self-test` | None (local test) | Validate core paths, Bash syntax, metadata and CLI dispatch without network |
| `ror update --check` | Network query only | Compare current branch with configured remote branch via `ls-remote` without remote-tracking mutation |
| `ror update` | **Updates local tracked files** | Require clean tree and perform `git pull --ff-only` |

Package profile names: `minimal`, `troubleshooting`, `networking`, `linux-admin`, `development`, `ansible`, `containers`, `kubernetes`, `cloud`. Supported dotfile groups vary by OS; `ror dotfiles status` and `ror dotfiles diff all` reveal relevant state. Never assume package installation has a safe automatic rollback; restore snapshots only for managed dotfile changes.

Bootstrap options are documented in [Bootstrap](../bootstrap/README.md): Unix `--profile PROFILE`, repeatable `--dotfiles GROUP`, `--no-doctor`; Windows PowerShell `-PackageProfile`, `-Dotfiles` and `-NoDoctor`. Plain bootstrap does not modify packages or dotfiles.

## Environmental and security considerations

- ROR is primarily a local Linux-oriented diagnostic/workflow toolkit with portable Bash and Windows wrapper; some diagnostics assume Linux/systemd, and some commands need optional installed tools/privileges.
- Network, DNS, SSH, NFS, TLS, Docker and Kubernetes diagnostics may contact target services, local daemon sockets or a selected cluster. They do not deliberately mutate configuration.
- Treat `ansible-inventory --host` values, `/etc/hosts` output, logs and collected reports as potentially sensitive; do not publish raw evidence.
- Managed dotfiles do not own Git username/email, credentials, SSH private key/config or host-specific local settings.
- Never copy secrets or internal infrastructure identifiers into this public repo. Its [Authoring Guide](resource-authoring.md) is the maintenance policy.

For task workflows continue to the [User Guide](user-guide.md) and [Operational Recipes](operational-recipes.md).