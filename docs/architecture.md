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
| `docs/` | Explanations, architecture, setup notes, and runbooks. |
| `tests/` | Portability, syntax, smoke, and repository-integrity validation. |
| `local/` | Repository-local machine state. Never committed. |

## Resource decision rule

- Need to **remember** something -> `cheat-sheets/`
- Need to **paste** something -> `snippets/`
- Need to **run** something -> `scripts/`
- Need to **perform a procedure safely** -> `docs/runbooks/`
- Need to **create a new artifact** -> `templates/`
- Need to **see everything related to a problem** -> `ror need <topic>`

## Safety model

Diagnostics and discovery are read-only by default. Mutating operations are explicit. Scripts should fail clearly rather than silently changing assumptions or configuration.

`ror diagnose` and `ror collect` use scripts under `scripts/diagnostics/`. Those collectors must not restart services, install packages, edit configuration, change permissions, or dump likely-secret sources such as process environment blocks. A network diagnostic may perform an ordinary lookup/connection attempt when that is the diagnostic's purpose.

`ror collect baseline` is the broadest collector. It combines existing system/network/storage/DNS collectors with security-mode visibility, firewall state, time synchronization, failed services, recent warning-or-higher journal output, kernel-package information, and reboot state. Proxy variables are reported only as present/not-present; their values are not emitted.

Tomcat diagnostics explicitly avoid `systemctl show ... Environment` because systemd unit environments can contain credentials or tokens.

`ror pkg install` and `ror dotfiles install` are intentionally explicit mutations. `ror doctor --install-suggestions`, `ror pkg suggest`, `ror dotfiles status`, `ror dotfiles diff`, `ror need`, `ror diagnose`, and `ror collect` remain read-only with respect to host configuration.

## Trust model

The default branch is expected to remain usable as a portable toolbox. GitHub Actions validates that promise with several layers:

1. **Parse/static checks** — Bash syntax, error-level ShellCheck, YAML, JSON, and PowerShell parsing.
2. **Repository integrity** — local Markdown links must resolve.
3. **Behavioral smoke tests** — core `ror` discovery, curated resource relationships, diagnostics, collection, package-profile, and dotfile lifecycle operations are exercised on Linux and Windows runners.
4. **Secret scanning** — full Git history is scanned for likely committed secrets.

Tests live under `tests/` so most validation can also be run locally rather than existing only inside CI.

The dotfile lifecycle smoke test uses a disposable HOME and verifies install/restore round trips without touching the runner's real configuration.

The initial ShellCheck gate intentionally blocks error-severity findings first. The lint bar can be tightened later as the existing script library is normalized.

## Doctor model

`ror doctor` is the lightweight first-look command. It should remain quick and mostly dependency-free while reporting enough information to decide what to inspect next.

Current health signals include:

- root filesystem pressure
- Linux memory pressure using `MemAvailable`
- failed systemd units when systemd is available
- time synchronization visibility
- SELinux/AppArmor visibility
- firewall visibility
- proxy presence without printing proxy values
- reboot-required visibility when the platform exposes it
- managed-dotfile status

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

The mapping lives in `lib/resources.sh` and connects aliases, recommended commands, and known resources. For example:

```text
certificate -> tls
sftp        -> ssh
pkix        -> java
filesystem  -> storage
k8s         -> kubernetes
```

A curated topic can link reference material, diagnostics, runbooks, snippets, templates, and managed configuration without moving or duplicating those resources.

The map is intentionally deterministic rather than fuzzy. This keeps behavior reviewable in Git and prevents a discovery command from becoming an opaque expert system. Unknown topics fall back to normal `ror find` search.

## Portability model

The repository exposes common user-facing operations while allowing platform-specific implementations underneath. OS support should be detected centrally through `lib/os.sh` rather than reimplemented independently in each script.

Package/tool naming differences belong in `lib/packages.sh`. For example, the user-facing tool `dig` maps to `bind-utils` on DNF-family systems and `dnsutils` on APT-family systems.

Dotfile lifecycle behavior belongs in `lib/dotfiles.sh` rather than being reimplemented in bootstrap or individual shell profiles.

Resource relationships belong in `lib/resources.sh` rather than being hard-coded across multiple commands or documentation files.

## Package profile model

Package profiles represent **capabilities**, not exact package lists. The current named profiles are:

- `minimal` — Git, curl, and jq.
- `troubleshooting` — general incident/host troubleshooting.
- `networking` — DNS, TCP, TLS, packet, and path troubleshooting.
- `linux-admin` — broad Linux administration/jumpbox toolkit.
- `development` — Git/Python/terminal development basics.
- `ansible` — distro-packaged Ansible control-node basics.
- `containers` — package-managed container prerequisites/runtime where sensible.
- `kubernetes` — common prerequisites; kubectl/helm remain explicit external tools.
- `cloud` — common prerequisites; gcloud/govc remain explicit external tools.

A profile may contain two classes of dependency:

1. **Package-managed items** — ROR can translate/install these through the detected package manager.
2. **External/vendor-specific tools** — ROR reports these when missing but does not pretend their installation is portable across every OS/repository configuration.

Single tool/package requests remain supported for backward compatibility.

## Dotfile model

ROR uses **managed fragments plus host include/source blocks**, not wholesale replacement.

Managed files live under:

```text
~/.config/ror/
```

Host integration is deliberately small and marked:

```text
# >>> ROR managed <group> >>>
...
# <<< ROR managed <group> <<<
```

Current groups are Bash/Readline, Git, tmux, and PowerShell when supported.

Before an install, every touched file is copied into a timestamped snapshot under:

```text
${XDG_STATE_HOME:-~/.local/state}/ror/dotfiles-backups/
```

`ROR_STATE_HOME` can override the state path for testing/special environments.

`ror dotfiles restore` restores files that existed before installation and removes managed files that were created by that installation. Backups remain after restore so rollback is repeatable/auditable.

Machine-specific Bash and PowerShell customization belongs under `~/.config/ror/local/` and is not written by the managed install.

Git identity, credentials, SSH private keys, host-specific SSH config, and Bash login-profile replacement are intentionally outside the automatic dotfile lifecycle.

## CLI model

`bin/ror` provides the common discovery, troubleshooting, reuse, and bootstrap interface:

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

Aliases are intentionally provided for common human variation (`find`/`search`, `cheat`/`cheatsheet`, `diagnose`/`diag`). `ror need` also normalizes topic aliases such as `sftp`/`ssh` and `certificate`/`tls`. A personal toolbox should be forgiving about how its owner remembers the command.

## Collection model

`ror collect <target>` runs the same read-only collector as `ror diagnose`, mirrors output to the terminal, and saves a timestamped handoff file in the current directory:

```text
ror-collect-<target>-<host>-<timestamp>.txt
```

Set `ROR_COLLECT_OUTPUT` when a specific output path is required. Generated default collection files are ignored by Git so running a collector from the repository directory does not dirty the working tree.

## Bootstrap model

Plain bootstrap installs only the ROR command wrapper and performs a read-only doctor check. Package profiles and dotfiles can be combined with bootstrap only through explicit flags/parameters.

This preserves one invariant: **cloning/bootstrap alone must not silently reconfigure a machine.**

See [`docs/setup/portable-workstation.md`](setup/portable-workstation.md) for the intended end-to-end workflow.

## Growth rule

New behavior should generally be added as a reusable resource first and surfaced through `ror` only when a stable interface is useful. Avoid adding top-level directories unless an existing directory contract genuinely cannot represent the resource.
