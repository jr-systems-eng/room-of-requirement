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

## Safety model

Diagnostics and discovery are read-only by default. Mutating operations are explicit. Scripts should fail clearly rather than silently changing assumptions or configuration.

## Portability model

The repository exposes common user-facing operations while allowing platform-specific implementations underneath. OS support should be detected centrally through `lib/os.sh` rather than reimplemented independently in each script.

## CLI model

`bin/ror` provides the common discovery and execution interface:

```text
ror doctor
ror info
ror find <term>
ror cheat <term>
ror run <script> [args...]
ror new <template> <destination>
ror update
```

As the project grows, new behavior should generally be added as a reusable resource first and surfaced through `ror` only when a stable interface is useful.
