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

`ror pkg install` is intentionally explicit. `ror doctor --install-suggestions` and `ror pkg suggest` only report what would be installed.

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

Set `ROR_COLLECT_OUTPUT` when a specific output path is required.

## Package bundles

The first portable bundles are:

- `troubleshooting` — curl, wget, jq, lsof, strace, tcpdump, DNS/TCP tools, OpenSSL, Git, tmux.
- `networking` — curl, jq, packet/DNS/TCP/TLS/path tools.
- `development` — Git, curl, jq, Python 3, tmux.

The abstraction is intentionally small; add mappings only when they are useful on more than one machine or platform.

## Growth rule

New behavior should generally be added as a reusable resource first and surfaced through `ror` only when a stable interface is useful. Avoid adding top-level directories unless an existing directory contract genuinely cannot represent the resource.
