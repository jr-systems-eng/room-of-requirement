# Room of Requirement Documentation

This is the documentation entry point for the current Room of Requirement CLI and resource collection. If this is your first visit, begin with the **User Guide**, not the architecture reference.

## Learn and use

1. **[User Guide](user-guide.md)** — what each feature does, when to use it, bootstrap, day-to-day commands, cautious apply model and handoffs.
2. **[Command & Feature Reference](command-reference.md)** — exact CLI syntax, aliases, diagnostic targets, arguments, scripts, workflow modes and side effects.
3. **[Operational Recipes](operational-recipes.md)** — copyable commands, expected outcomes, follow-up decisions and common errors across 12 engineering scenarios.
4. **[Runbook Index](runbooks/README.md)** — detailed manual incident/change procedures, validation and rollback.
5. **[Portable Workstation Setup](setup/portable-workstation.md)** — complete install, package/dotfiles and recovery procedure.
6. **[AI Agent Standards Workflow](setup/agent-standards-workflow.md)** — Cursor/repository instructions, work orders, Cloud checkout, audits and PR/handoff process.

## Maintain and extend

- [Architecture](architecture.md) — operational layers, module boundaries and portability model.
- [Philosophy](philosophy.md) — design/safety principles.
- [Resource Authoring](resource-authoring.md) — when to add a room, diagnostic, script, workflow, runbook, snippet or template and how to validate it.
- [Room Metadata](../config/room/README.md) — topics/actions/resources contracts.
- [Workflow Metadata](../config/workflows/README.md) — modes, maturity, registry format and guards.
- [Test Guide](../tests/README.md) — local smoke/metadata/link tests and CI intent.
- [Change History](../CHANGELOG.md) — capabilities by release.

## Browse the library

- [Cheat Sheets](../cheat-sheets/README.md) and [Snippets](../snippets/README.md)
- [Diagnostics](../scripts/diagnostics/README.md) and [Scripts](../scripts/README.md)
- [Workflows](../workflows/README.md) and [Templates](../templates/README.md)
- [Managed Dotfiles](../dotfiles/README.md)
- [Bootstrap](../bootstrap/README.md)

## Fastest decision path

| Need | Starting point |
| --- | --- |
| Learn the toolbox | [User Guide](user-guide.md) |
| Find exact syntax | [Command Reference](command-reference.md) |
| Solve a familiar incident | [Operational Recipes](operational-recipes.md) |
| Inspect an issue | `ror need TOPIC` then `ror diagnose TARGET` |
| Follow a risky change | First read the runbook, then inspect `ror workflow NAME` without `--apply` |
| Create reusable project scaffolding | `ror new TEMPLATE DESTINATION` |
| Verify local installation | `ror doctor` and `ror self-test` |

**Source of truth:** This repository's checked-in code, metadata and docs. Private Obsidian notes can summarize a personal workflow but should link here for exact command contracts.