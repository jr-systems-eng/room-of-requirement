# Architecture

Room of Requirement is organized by **how a resource is used**, not by the machine it came from.

## Directory contracts

| Path | Purpose |
|---|---|
| `bin/` | User-facing commands. `ror` is the primary entrypoint. |
| `lib/` | Shared implementation used by commands and scripts. Not invoked directly. |
| `bootstrap/` | Safe setup of ROR on a new machine. |
| `cheat-sheets/` | Quick-reference material: "How does this work again?" |
| `snippets/` | Paste-ready fragments: "Give me the reusable few lines." |
| `scripts/` | Complete utilities that perform one defined task. |
| `templates/` | Known-good starting files for creating something new. |
| `dotfiles/` | Portable managed shell/tool configuration fragments. |
| `docs/` | Explanations, architecture, setup notes, authoring guidance, and runbooks. |
| `tests/` | Portability, syntax, smoke, and repository-integrity validation. |
| `local/` | Repository-local machine state. Never committed. |

## Resource decision rule

- Need to **remember** something -> `cheat-sheets/`
- Need to **paste** something -> `snippets/`
- Need to **run** something -> `scripts/`
- Need to **perform a procedure safely** -> `docs/runbooks/`
- Need to **create a new artifact** -> `templates/`
- Need to **see everything related to a problem** -> `ror need <topic>`

The [Resource Authoring Guide](resource-authoring.md) is the maintenance contract for adding new library content.

## Safety model

Diagnostics and discovery are read-only by default. Mutating operations are explicit. Scripts should fail clearly rather than silently changing assumptions or configuration.

`ror diagnose` and `ror collect` use scripts under `scripts/diagnostics/`. Those collectors must not restart services, install packages, edit configuration, change permissions, or dump likely-secret sources such as process environment blocks. A network diagnostic may perform an ordinary read-only lookup/connection attempt when that is the diagnostic's purpose.

`ror collect baseline` is the broadest collector. It combines existing system/network/storage/DNS collectors with security-mode visibility, firewall state, time synchronization, failed services, recent warning-or-higher journal output, kernel-package information, and reboot state. Proxy variables are reported only as present/not-present; their values are not emitted.

Tomcat diagnostics explicitly avoid `systemctl show ... Environment` because unit environments can contain credentials or tokens.

`ror pkg install` and `ror dotfiles install` are intentionally explicit mutations. `ror doctor --install-suggestions`, `ror pkg suggest`, `ror dotfiles status`, `ror dotfiles diff`, `ror need`, `ror diagnose`, and `ror collect` remain read-only with respect to host configuration.

## Trust model

The default branch is expected to remain usable as a portable toolbox. GitHub Actions validates that promise with several layers:

1. **Parse/static checks** — Bash syntax, error-level ShellCheck, YAML, JSON, and PowerShell parsing.
2. **Repository integrity** — local Markdown links must resolve.
3. **Behavioral smoke tests** — core `ror` discovery, curated relationships, diagnostics, collection, template-copy, package-profile, and dotfile lifecycle operations are exercised on Linux and Windows runners.
4. **Relationship integrity** — every resource path declared by a curated `ror need` topic must exist.
5. **Secret scanning** — full Git history is scanned for likely committed secrets.

Tests live under `tests/` so most validation can also be run locally rather than existing only inside CI.

The dotfile lifecycle smoke test uses a disposable HOME and verifies install/restore round trips without touching the runner's real configuration.

## Doctor model

`ror doctor` is the lightweight first-look command. It should remain quick and mostly dependency-free while reporting enough information to decide what to inspect next.

Current health signals include root filesystem pressure, Linux memory pressure using `MemAvailable`, failed systemd units, time synchronization, SELinux/AppArmor visibility, firewall visibility, proxy presence without values, reboot-required visibility, and managed-dotfile status.

Doctor findings are advisory. A warning identifies something worth reviewing; it is not automatically a diagnosis.

## Diagnostic interpretation model

Targeted diagnostics may add a final `SUMMARY` section when the collector has enough direct evidence to make simple observations.

Interpretation follows these rules:

1. **Raw evidence first.** The underlying command output remains visible above the summary.
2. **Observed facts, not invented causes.** Examples include "service inactive," "port not listening," "verify code non-zero," or "filesystem >=90%."
3. **High-signal pattern detection only.** Log matching is reserved for recognizable conditions such as SSH KEX mismatches, Java PKIX failures, Tomcat bind conflicts, or `OutOfMemoryError`.
4. **Warnings are investigative.** `WARN` means the evidence deserves attention; it does not mean ROR has proven the root cause.
5. **Next steps stay inspectable.** Suggested commands point back to collectors, runbooks, or ordinary OS tools.

Current interpreted targets include systemd, SSH, TLS, DNS, storage, Java, and Tomcat.

## Resource relationship model

`ror find` remains literal repository search. `ror need` adds a curated relationship layer for common engineering topics.

The mapping lives in `lib/resources.sh` and connects aliases, recommended commands, and known resources. Example aliases include:

```text
certificate -> tls
sftp        -> ssh
nfs4        -> nfs
memory      -> performance
pkix        -> java
k8s         -> kubernetes
tf          -> terraform
actions     -> github
```

A curated topic can link reference material, diagnostics, runbooks, snippets, templates, guides, and managed configuration without moving or duplicating those resources.

The map is intentionally deterministic rather than fuzzy. This keeps behavior reviewable in Git and prevents a discovery command from becoming an opaque expert system. Unknown topics fall back to normal `ror find` search.

Every declared curated path is validated by the smoke suite. This prevents the normal existence guard in `ror need` from silently hiding a stale mapping after a file is renamed.

## Reuse/template model

Templates are single-file starting points because `ror new` currently copies one file at a time. They use `__TOKEN__` placeholders, contain no real credentials/environment identity, and should bias toward safe/least-privilege defaults.

Phase 6 expands the template families for Ansible, Docker, Kubernetes, GitHub Actions/PR review, and Terraform. Directory trees/roles/modules may be added later if `ror new` gains directory-copy/substitution behavior.

Runbooks complement templates: templates answer **what should I start from?**, while runbooks answer **what ordered procedure should I follow and how do I validate it?**

## Portability model

The repository exposes common user-facing operations while allowing platform-specific implementations underneath. OS support should be detected centrally through `lib/os.sh` rather than reimplemented independently in each script.

Package/tool naming differences belong in `lib/packages.sh`. Dotfile lifecycle behavior belongs in `lib/dotfiles.sh`. Curated resource relationships belong in `lib/resources.sh`.

## Package profile model

Package profiles represent capabilities rather than exact package lists. Current profiles are `minimal`, `troubleshooting`, `networking`, `linux-admin`, `development`, `ansible`, `containers`, `kubernetes`, and `cloud`.

A profile may contain package-manager-installable items and external/vendor-specific tools. ROR reports vendor-specific tools when missing but does not pretend their installation is portable across every OS/repository configuration.

## Dotfile model

ROR uses managed fragments plus host include/source blocks, not wholesale replacement. Managed files live under `~/.config/ror/`; backups live under `${XDG_STATE_HOME:-~/.local/state}/ror/dotfiles-backups/` unless overridden by `ROR_STATE_HOME`.

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
ror dotfiles status
ror dotfiles diff [group|all]
ror dotfiles install <group|all>
ror dotfiles backups
ror dotfiles restore [latest|backup-id]
ror update
```

Aliases are intentionally provided for common human variation. A personal toolbox should be forgiving about how its owner remembers the command.

## Collection model

`ror collect <target>` runs the same read-only collector as `ror diagnose`, mirrors output to the terminal, and saves a timestamped handoff file in the current directory:

```text
ror-collect-<target>-<host>-<timestamp>.txt
```

Set `ROR_COLLECT_OUTPUT` when a specific output path is required. Generated default collection files are ignored by Git.

## Bootstrap model

Plain bootstrap installs only the ROR command wrapper and performs a read-only doctor check. Package profiles and dotfiles can be combined with bootstrap only through explicit flags/parameters.

This preserves one invariant: **cloning/bootstrap alone must not silently reconfigure a machine.**

See [Portable Workstation Setup](setup/portable-workstation.md) for the intended workflow.

## Growth rule

New behavior should generally be added as a reusable resource first and surfaced through `ror` only when a stable interface is useful. Avoid adding top-level directories unless an existing directory contract genuinely cannot represent the resource.

When a new resource is added, update its category index, curated relationship map when useful, relevant smoke coverage, user/admin documentation, and changelog in the same capability batch whenever practical.
