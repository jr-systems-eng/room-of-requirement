# Philosophy

**Copy-based. Safe. Portable.**

Room of Requirement is a portable engineering toolbox: clone it onto an unfamiliar machine and have useful reference material, diagnostics, reusable scripts, templates, and configuration immediately available.

## Principles

1. **Portable by default** — resources should not depend on the machine they were authored on.
2. **OS-aware, not OS-bound** — platform-specific implementations are fine behind a common interface.
3. **Read-only by default** — diagnostics and discovery should not change the target system.
4. **Explicit mutation** — commands that modify files, packages, configuration, or Git state must be intentional and visible.
5. **No secrets in Git** — machine-local state and credentials belong under `local/` or in an external secrets manager.
6. **Copy over symlink when safety matters** — bootstrap/install operations should avoid unexpectedly replacing existing user configuration.
7. **Graceful degradation** — optional tools improve functionality, but the core should remain useful on minimal systems.
8. **Discoverability matters** — a useful resource that cannot be found quickly is not useful enough.

## Resource model

- `cheat-sheets/` — remember how something works.
- `snippets/` — copy/paste a small reusable fragment.
- `scripts/` — run a complete utility.
- `templates/` — create something from a known-good starting point.
- `docs/runbooks/` — follow a safe procedure.
- `dotfiles/` — portable user-environment defaults.
- `local/` — machine-specific state that must never be committed.
- `bootstrap/` — make a new machine ready to use the toolbox.
- `bin/ror` — the front door to the repository.
