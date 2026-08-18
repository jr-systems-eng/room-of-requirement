# Architecture

Room of Requirement is organized by **how a resource is used**, not by the machine it came from.

## Directory contracts

| Path | Purpose |
|---|---|
| `bin/` | User-facing commands. `ror` is the primary entrypoint. |
| `lib/` | Shared implementation used by commands/scripts. Not invoked directly. |
| `config/room/` | Deterministic topic/action/resource/relationship metadata for `ror need`. |
| `bootstrap/` | Safe setup of ROR on a new machine. |
| `cheat-sheets/` | Quick-reference material: "How does this work again?" |
| `snippets/` | Paste-ready fragments: "Give me the reusable few lines." |
| `scripts/diagnostics/` | Read-only evidence collectors exposed through `ror diagnose`/`collect`. |
| `scripts/<area>/` | Complete operational utilities with one defined purpose. |
| `templates/` | Known-good starting files for creating something new. |
| `dotfiles/` | Portable managed shell/tool configuration fragments. |
| `docs/runbooks/` | Ordered administration/troubleshooting procedures. |
| `docs/` | Architecture, setup, authoring guidance, and explanatory material. |
| `tests/` | Portability, syntax, smoke, metadata, and repository-integrity validation. |
| `local/` | Repository-local machine state. Never committed. |

## Resource decision rule

- Need to **remember** something -> `cheat-sheets/`
- Need to **paste** something -> `snippets/`
- Need to **run a complete utility** -> `scripts/<area>/`
- Need to **collect troubleshooting evidence** -> `scripts/diagnostics/`
- Need to **perform a procedure safely** -> `docs/runbooks/`
- Need to **create a new artifact** -> `templates/`
- Need to **see everything related to a problem** -> `ror need <topic>`

The [Resource Authoring Guide](resource-authoring.md) is the maintenance contract for adding content.

## Safety model

Discovery and diagnostics are read-only by default. Mutating operations are explicit. Scripts should fail clearly rather than silently changing assumptions or configuration.

`ror diagnose`/`ror collect` must not restart services, install packages, edit configuration, change permissions, mutate containers/Kubernetes workloads, or dump likely-secret surfaces. Ordinary connection, lookup, and read-only API attempts are allowed when they are the diagnostic purpose.

Examples of intentionally excluded surfaces:

- process/container environment blocks;
- systemd unit `Environment` values;
- raw Kubernetes kubeconfig;
- Kubernetes Secret objects;
- credential-bearing Git remote URLs.

`ror pkg install` and `ror dotfiles install` are explicit mutations. `ror doctor --install-suggestions`, `ror pkg suggest`, `ror dotfiles status/diff`, `ror need`, `ror diagnose`, `ror collect`, and the Phase 7 operational utilities remain read-only with respect to system/workload configuration.

## Trust model

The default branch is expected to remain usable as a portable toolbox. GitHub Actions validates that promise with several layers:

1. **Parse/static checks** — Bash syntax, error-level ShellCheck, YAML, JSON, and PowerShell parsing.
2. **Repository integrity** — local Markdown links must resolve.
3. **Room metadata integrity** — aliases are unique, related topics exist, topic ownership is valid, and every declared resource path exists.
4. **Behavioral smoke tests** — core CLI discovery, metadata-backed Rooms, diagnostics, collection, template copying, operational utilities, package profiles, and dotfile lifecycle operations are exercised on Linux/Windows runners where portable.
5. **Secret scanning** — full Git history is scanned for likely committed secrets.

Tests live under `tests/` so most validation can run locally as well as in CI.

## Room/relationship model

`ror find` is literal repository search. `ror need` is a curated deterministic relationship layer.

Phase 7 moves topic knowledge from a growing shell `case` statement into three plain-text metadata files:

```text
config/room/topics.tsv
config/room/actions.tsv
config/room/resources.tsv
```

The runtime deliberately uses a simple pipe-delimited format so Bash needs no YAML/JSON parser. CI applies stricter Python validation.

`topics.tsv` owns canonical names, aliases, descriptions, and related rooms. `actions.tsv` owns ordered suggested commands. `resources.tsv` connects repository paths and resource types to topics.

Example mental model:

```text
memory -> performance
            |
            +-- diagnostic: scripts/diagnostics/performance.sh
            +-- runbook: investigate-memory-pressure.md
            +-- related room: storage
            +-- related room: systemd
            +-- related room: tomcat
```

`ror need` presents:

1. Purpose.
2. **Start here** (first action).
3. Follow-up actions.
4. Grouped resources.
5. **Related rooms**.

Related rooms are navigation links, not causal inference. The command remains read-only and does not automatically execute suggested actions.

## Diagnostic interpretation model

Targeted diagnostics may add a final `SUMMARY` when direct evidence supports simple observations.

Rules:

1. **Raw evidence first.** Underlying command output stays visible.
2. **Observed facts, not invented causes.** Examples: service inactive, listener absent, verify code non-zero, filesystem >=90%, D-state tasks present.
3. **High-signal pattern detection only.** Avoid broad log inference.
4. **Warnings are investigative.** `WARN` identifies evidence worth reviewing; it does not prove root cause.
5. **Next steps remain inspectable.** Suggested commands point to ordinary tools/runbooks/Rooms.

Phase 7 expands interpreted diagnostics with:

- `performance` — load vs CPU count, MemAvailable pressure, blocked tasks, OOM evidence;
- `nfs` — local mounts/exports/server/listener state plus optional TCP/2049 reachability;
- `docker` — daemon/context/container state without environment inspection;
- `kubernetes` — API reachability, node/pod observations without Secret/raw-kubeconfig reads.

Existing interpreted targets include systemd, SSH, TLS, DNS, storage, Java, and Tomcat.

## Operational utility model

Standalone utilities under `scripts/<area>/` answer narrow day-to-day questions without requiring a full diagnostic collector.

Initial Phase 7 utilities:

- `system/port-process.sh` — which local process owns/listens on a port?
- `networking/cert-expiry.sh` — what certificate is served and is it inside a warning window?
- `git/repo-health.sh` — branch/worktree/upstream/ahead-behind state without remote URL leakage;
- `kubernetes/workload-summary.sh` — compact namespace workload/pod status without Secret reads.

Utilities remain inspectable and single-purpose. `ror run` is the generic execution interface.

## Doctor model

`ror doctor` is the lightweight first-look command. It remains quick and mostly dependency-free while reporting platform/tooling plus root filesystem pressure, Linux `MemAvailable` pressure, failed systemd units, time sync, MAC/firewall visibility, proxy presence without values, reboot status, managed dotfiles, and repository state.

Doctor findings are advisory.

## Reuse/template model

Templates are single-file starting points because `ror new` currently copies one file at a time. They use `__TOKEN__` placeholders, contain no real credentials/environment identity, and bias toward safe/least-privilege defaults.

Runbooks complement templates: templates answer **what should I start from?**, runbooks answer **what ordered procedure should I follow and how do I validate it?**

## Portability model

Common user-facing operations should hide platform naming/implementation differences without hiding evidence.

- OS detection belongs in `lib/os.sh`.
- Package/tool translation belongs in `lib/packages.sh`.
- Dotfile lifecycle belongs in `lib/dotfiles.sh`.
- Room metadata runtime behavior belongs in `lib/resources.sh`; topic knowledge belongs in `config/room/`.

Vendor-specific tools that cannot be installed portably are reported rather than silently guessed.

## Package profile model

Profiles represent capabilities rather than exact package lists: `minimal`, `troubleshooting`, `networking`, `linux-admin`, `development`, `ansible`, `containers`, `kubernetes`, and `cloud`.

A profile may include package-manager-installable dependencies and external/vendor-specific tools. External tools are reported when missing but not silently installed through guessed procedures.

## Dotfile model

ROR uses managed fragments plus host include/source blocks, not wholesale replacement. Managed files live under `~/.config/ror/`; backups live under `${XDG_STATE_HOME:-~/.local/state}/ror/dotfiles-backups/` unless `ROR_STATE_HOME` overrides it.

`ror dotfiles restore` restores files that existed before installation and removes managed files created by that transaction. Git identity, credentials, SSH private keys/config, and machine-specific settings remain outside automatic management.

## CLI model

```text
ror doctor [--install-suggestions]
ror info
ror path [resource]
ror need [topic|list]
ror find [--type TYPE] <term>
ror search [--type TYPE] <term>
ror cheat <term>
ror diagnose <target> [args...]
ror collect <target> [args...]
ror run <script> [args...]
ror new <template> <destination>
ror pkg list|suggest|install [profile-or-package]
ror dotfiles status|diff|install|backups|restore ...
ror update
```

Aliases are intentionally provided for common human variation. A personal toolbox should be forgiving about how its owner remembers a command/topic.

## Collection model

`ror collect <target>` runs the same read-only collector as `ror diagnose`, mirrors output to the terminal, and saves:

```text
ror-collect-<target>-<host>-<timestamp>.txt
```

Set `ROR_COLLECT_OUTPUT` to select a specific path. Generated default files are ignored by Git.

## Bootstrap model

Plain bootstrap installs only the ROR wrapper and performs a read-only doctor check. Package profiles/dotfiles require explicit flags/parameters.

Invariant: **cloning/bootstrap alone must not silently reconfigure a machine.**

See [Portable Workstation Setup](setup/portable-workstation.md).

## Growth rule

New behavior should generally be added as a reusable resource first and surfaced through `ror` when a stable interface is useful. Avoid new top-level directories unless an existing contract cannot represent the resource.

When a capability is added, update its category index, Room metadata, tests, user/admin documentation, and changelog in the same batch whenever practical.
