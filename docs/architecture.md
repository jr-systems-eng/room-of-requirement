# Architecture

Room of Requirement is organized by **how a resource is used**, not by the machine it came from.

## Directory contracts

| Path | Purpose |
|---|---|
| `bin/` | User-facing commands. `ror` is the primary entrypoint. |
| `lib/` | Shared implementation used by commands/scripts. Not invoked directly. |
| `config/room/` | Deterministic topic/action/resource/relationship metadata for `ror need`. |
| `config/workflows/` | Deterministic workflow registry: names, aliases, modes, status, descriptions, implementation paths. |
| `workflows/` | Guided operational procedures with preflight/plan/apply/validation contracts. |
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
| `VERSION` | Current repository/CLI semantic version. |

## Resource decision rule

- Need to **remember** something -> `cheat-sheets/`
- Need to **paste** something -> `snippets/`
- Need to **run a complete utility** -> `scripts/<area>/`
- Need to **collect troubleshooting evidence** -> `scripts/diagnostics/`
- Need to **follow a detailed manual procedure** -> `docs/runbooks/`
- Need to **execute a constrained operational procedure** -> `workflows/`
- Need to **create a new artifact** -> `templates/`
- Need to **see everything related to a problem** -> `ror need <topic>`

The [Resource Authoring Guide](resource-authoring.md) is the maintenance contract for adding content.

## Operational layer model

The CLI has four intentionally distinct layers:

```text
ror need        -> discover related knowledge/resources
ror diagnose    -> collect and interpret current state
ror workflow    -> present/execute an ordered procedure with explicit change boundaries
ror run         -> execute one narrow utility
```

A workflow should not replace a runbook when human interpretation remains important. The runbook explains the broader decision space; the workflow encodes only the portion whose preconditions, changes, validation, and rollback behavior are constrained enough to automate safely.

## Safety model

Discovery and diagnostics are read-only by default. Mutating operations are explicit. Scripts should fail clearly rather than silently changing assumptions or configuration.

`ror diagnose`/`ror collect` must not restart services, install packages, edit configuration, change permissions, mutate containers/Kubernetes workloads, or dump likely-secret surfaces. Ordinary connection, lookup, and read-only API attempts are allowed when they are the diagnostic purpose.

Examples of intentionally excluded surfaces:

- process/container environment blocks;
- systemd unit `Environment` values;
- raw Kubernetes kubeconfig;
- Kubernetes Secret objects;
- credential-bearing Git remote URLs.

`ror pkg install` and `ror dotfiles install` are explicit mutations. `ror doctor --install-suggestions`, `ror pkg suggest`, `ror dotfiles status/diff`, `ror need`, `ror diagnose`, `ror collect`, operational utilities, `ror version`, `ror self-test`, and `ror update --check` are non-mutating with respect to host/application configuration.

### Workflow mutation boundary

Workflow modes are declared in `config/workflows/index.tsv`:

- `read-only` — no apply path; inspection/validation only.
- `preparation` — no apply path; prepares evidence/change/backup guidance only.
- `plan-apply` — default invocation must be non-mutating; mutation requires an explicit `--apply` supplied by the user.

A `plan-apply` workflow must:

1. expose preflight evidence before mutation;
2. print the intended plan;
3. refuse apply on blocking preflight findings;
4. make only the narrow changes described by its registry entry;
5. validate the result after apply;
6. print concrete rollback guidance when rollback is meaningful;
7. never silently install prerequisites or broaden scope.

Phase 8 intentionally does **not** automate LVM/filesystem growth. Storage expansion remains runbook-only until the workflow framework has more field evidence.

## Workflow maturity model

Workflow status is separate from version number and CI status:

- `experimental` — code/metadata may be CI-clean but requires representative field testing before broad trust;
- `stable` — behavior, failure modes, validation, and rollback contract have been field-tested sufficiently for routine use;
- `deprecated` — retained for compatibility but no longer preferred.

All workflows introduced in Phase 8 begin as `experimental`. CI passing is necessary but is not enough to promote a workflow.

## Trust model

The default branch is expected to remain usable as a portable toolbox. GitHub Actions validates that promise with several layers:

1. **Parse/static checks** — Bash syntax, error-level ShellCheck, YAML, JSON, and PowerShell parsing. `workflows/` is included in Bash/ShellCheck coverage.
2. **Repository integrity** — local Markdown links must resolve.
3. **Room metadata integrity** — aliases are unique, related topics exist, topic ownership is valid, and every declared resource path exists.
4. **Workflow metadata integrity** — names/aliases are unique, modes/statuses are valid, implementation paths are safe/existing/executable, and `plan-apply` workflows expose an explicit apply path.
5. **Behavioral smoke tests** — core CLI discovery, metadata-backed Rooms, diagnostics, collection, template copying, operational utilities, workflow plan/read-only paths, package profiles, and dotfile lifecycle operations are exercised on Linux/Windows runners where portable.
6. **Secret scanning** — full Git history is scanned for likely committed secrets.

CI intentionally does **not** invoke workflow `--apply` paths. Mutating workflow behavior must be field-tested on representative systems rather than simulated as proof of production safety.

Tests live under `tests/` so most validation can run locally as well as in CI.

## Room/relationship model

`ror find` is literal repository search. `ror need` is a curated deterministic relationship layer.

Topic knowledge lives in three plain-text metadata files:

```text
config/room/topics.tsv
config/room/actions.tsv
config/room/resources.tsv
```

The runtime deliberately uses a simple pipe-delimited format so Bash needs no YAML/JSON parser. CI applies stricter Python validation.

`topics.tsv` owns canonical names, aliases, descriptions, and related rooms. `actions.tsv` owns ordered suggested commands. `resources.tsv` connects repository paths and resource types to topics, including workflows where useful.

Example:

```text
nfs
 |
 +-- diagnostic: scripts/diagnostics/nfs.sh
 +-- workflow: workflows/nfs-client.sh
 +-- runbook: configure-nfs-share.md
 +-- related room: network
 +-- related room: storage
```

`ror need` presents purpose, **Start here**, follow-up actions, grouped resources, and **Related rooms**. Related rooms are navigation links, not causal inference. The command remains read-only and does not automatically execute suggested actions.

## Workflow registry/runtime model

`config/workflows/index.tsv` uses:

```text
name|aliases|mode|status|description|script
```

`lib/workflows.sh` is a generic registry reader/dispatcher. Workflow-specific knowledge remains in metadata and the implementation script rather than accumulating as new CLI `case` logic.

`ror workflow list` renders name/mode/status/description. `ror workflow <name> ...` resolves aliases, prints the registry header, then executes the registered script.

The Phase 8 set is:

- `nfs-client` — guarded NFSv4 client mount with optional `/etc/fstab` + systemd automount persistence;
- `service-recovery` — inspect/restart/validate one systemd unit without config edits;
- `workstation` — combine existing package-profile and managed-dotfile operations;
- `ansible-inventory` — read-only inventory parsing/graph/host-variable inspection without managed-host connections;
- `certificate-deploy-prep` — certificate/key/chain/target preparation with no deployment path.

## Diagnostic interpretation model

Targeted diagnostics may add a final `SUMMARY` when direct evidence supports simple observations.

Rules:

1. **Raw evidence first.** Underlying command output stays visible.
2. **Observed facts, not invented causes.** Examples: service inactive, listener absent, verify code non-zero, filesystem >=90%, D-state tasks present.
3. **High-signal pattern detection only.** Avoid broad log inference.
4. **Warnings are investigative.** `WARN` identifies evidence worth reviewing; it does not prove root cause.
5. **Next steps remain inspectable.** Suggested commands point to ordinary tools/runbooks/Rooms/workflows.

Interpreted operational diagnostics include performance, NFS, Docker, Kubernetes, systemd, SSH, TLS, DNS, storage, Java, and Tomcat.

## Operational utility model

Standalone utilities under `scripts/<area>/` answer narrow day-to-day questions without requiring a full diagnostic collector.

Current utilities include:

- `system/port-process.sh` — which local process owns/listens on a port?
- `networking/cert-expiry.sh` — what certificate is served and is it inside a warning window?
- `git/repo-health.sh` — branch/worktree/upstream/ahead-behind state without remote URL leakage;
- `kubernetes/workload-summary.sh` — compact namespace workload/pod status without Secret reads.

Utilities remain inspectable and single-purpose. `ror run` is the generic execution interface.

## Doctor model

`ror doctor` is the lightweight first-look command. It remains quick and mostly dependency-free while reporting version, platform/tooling, root filesystem pressure, Linux `MemAvailable` pressure, failed systemd units, time sync, MAC/firewall visibility, proxy presence without values, reboot status, managed dotfiles, and repository state.

Doctor findings are advisory.

## Version/update/self-test model

`VERSION` is the explicit repository semantic version source. Version progression is not tied to a fixed number of pre-1.0 phases; `0.x.y` can continue as long as field maturity requires.

`ror version` reports VERSION plus local Git commit/branch/worktree state.

`ror update --check` uses `git ls-remote` against the configured upstream branch to compare the remote SHA without updating remote-tracking refs or printing the remote URL.

`ror self-test` is local, read-only, and network-independent. It checks required repository paths, core Bash syntax, Room/workflow metadata when Python is available, and basic CLI discovery/version/workflow dispatch.

`ror update` still requires a clean worktree and uses `git pull --ff-only`.

## Reuse/template model

Templates are single-file starting points because `ror new` currently copies one file at a time. They use `__TOKEN__` placeholders, contain no real credentials/environment identity, and bias toward safe/least-privilege defaults.

Runbooks complement templates and workflows:

- templates answer **what should I start from?**
- runbooks answer **what procedure/decision path should I understand?**
- workflows answer **what constrained sequence can ROR safely guide/execute?**

## Portability model

Common user-facing operations should hide platform naming/implementation differences without hiding evidence.

- OS detection belongs in `lib/os.sh`.
- Package/tool translation belongs in `lib/packages.sh`.
- Dotfile lifecycle belongs in `lib/dotfiles.sh`.
- Room metadata runtime behavior belongs in `lib/resources.sh`; topic knowledge belongs in `config/room/`.
- Workflow registry behavior belongs in `lib/workflows.sh`; workflow identity/maturity belongs in `config/workflows/`; procedure implementation belongs in `workflows/`.

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
ror version
ror path [resource]
ror need [topic|list]
ror workflow list
ror workflow <name> [args...]
ror find [--type TYPE] <term>
ror search [--type TYPE] <term>
ror cheat <term>
ror diagnose <target> [args...]
ror collect <target> [args...]
ror run <script> [args...]
ror new <template> <destination>
ror pkg list|suggest|install [profile-or-package]
ror dotfiles status|diff|install|backups|restore ...
ror self-test
ror update --check
ror update
```

Aliases are intentionally provided for common human variation. A personal toolbox should be forgiving about how its owner remembers a command/topic/workflow.

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

New behavior should generally be added as a reusable resource first and surfaced through `ror` when a stable interface is useful. A new top-level directory is justified only when an existing contract cannot represent the resource; `workflows/` is such a distinct contract because it encodes guided, optionally mutating procedures rather than references, utilities, or runbooks.

When a capability is added, update its category index, Room/workflow metadata where relevant, tests, user/admin documentation, and changelog in the same batch whenever practical.
