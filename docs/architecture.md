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
| `dotfiles/` | Portable shell/tool configuration defaults. |
| `docs/` | Explanations, architecture, setup notes, and runbooks. |
| `tests/` | Portability, syntax, smoke, and repository-integrity validation. |
| `local/` | Machine-specific state. Never committed. |

## Resource decision rule

- Need to **remember** something -> `cheat-sheets/`
- Need to **paste** something -> `snippets/`
- Need to **run** something -> `scripts/`
- Need to **perform a procedure safely** -> `docs/runbooks/`
- Need to **create a new artifact** -> `templates/`

## Safety model

Diagnostics and discovery are read-only by default. Mutating operations are explicit. Scripts should fail clearly rather than silently changing assumptions or configuration.

`ror diagnose` and `ror collect` use scripts under `scripts/diagnostics/`. Those collectors must not restart services, install packages, edit configuration, change permissions, or dump likely-secret sources such as process environment blocks. A network diagnostic may perform an ordinary lookup/connection attempt when that is the diagnostic's purpose.

`ror collect baseline` is the broadest collector. It combines existing system/network/storage/DNS collectors with security-mode visibility, firewall state, time synchronization, failed services, recent warning-or-higher journal output, kernel-package information, and reboot state. Proxy variables are reported only as present/not-present; their values are not emitted.

`ror pkg install` is intentionally explicit. `ror doctor --install-suggestions` and `ror pkg suggest` only report what would be installed.

## Trust model

The default branch is expected to remain usable as a portable toolbox. GitHub Actions validates that promise with several layers:

1. **Parse/static checks** — Bash syntax, error-level ShellCheck, YAML, JSON, and PowerShell parsing.
2. **Repository integrity** — local Markdown links must resolve.
3. **Behavioral smoke tests** — core `ror` discovery, reference, diagnostics, and collection operations are exercised on Linux and Windows runners.
4. **Secret scanning** — full Git history is scanned for likely committed secrets.

Tests live under `tests/` so most validation can also be run locally rather than existing only inside CI.

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

Doctor findings are advisory. A warning identifies something worth reviewing; it is not automatically a diagnosis.

## Portability model

The repository exposes common user-facing operations while allowing platform-specific implementations underneath. OS support should be detected centrally through `lib/os.sh` rather than reimplemented independently in each script.

Package/tool naming differences belong in `lib/packages.sh`. For example, the user-facing tool `dig` maps to `bind-utils` on DNF-family systems and `dnsutils` on APT-family systems.

## CLI model

`bin/ror` provides the common discovery, troubleshooting, reuse, and bootstrap interface:

```text
ror doctor [--install-suggestions]
ror info
ror path [resource]
ror find [--type TYPE] <term>
ror search [--type TYPE] <term>
ror cheat <term>
ror diagnose <target> [args...]
ror collect <target> [args...]
ror run <script> [args...]
ror new <template> <destination>
ror pkg list|suggest|install [bundle-or-package]
ror dotfiles status
ror update
```

Aliases are intentionally provided for common human variation (`find`/`search`, `cheat`/`cheatsheet`, `diagnose`/`diag`). A personal toolbox should be forgiving about how its owner remembers the command.

## Collection model

`ror collect <target>` runs the same read-only collector as `ror diagnose`, mirrors output to the terminal, and saves a timestamped handoff file in the current directory:

```text
ror-collect-<target>-<host>-<timestamp>.txt
```

Set `ROR_COLLECT_OUTPUT` when a specific output path is required. Generated default collection files are ignored by Git so running a collector from the repository directory does not dirty the working tree.

## Package bundles

The first portable bundles are:

- `troubleshooting` — curl, wget, jq, lsof, strace, tcpdump, DNS/TCP tools, OpenSSL, Git, tmux.
- `networking` — curl, jq, packet/DNS/TCP/TLS/path tools.
- `development` — Git, curl, jq, Python 3, tmux.

The abstraction is intentionally small; add mappings only when they are useful on more than one machine or platform.

## Growth rule

New behavior should generally be added as a reusable resource first and surfaced through `ror` only when a stable interface is useful. Avoid adding top-level directories unless an existing directory contract genuinely cannot represent the resource.
