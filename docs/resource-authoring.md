# Resource Authoring Guide

This guide defines the maintenance checklist for adding reusable material to Room of Requirement.

The goal is to keep the repository portable, discoverable, safe, and internally consistent as it grows.

## Choose the correct resource type

- `cheat-sheets/` — concise reference material for remembering commands/concepts.
- `snippets/` — short copy/paste fragments.
- `scripts/` — executable utilities with one defined purpose.
- `scripts/diagnostics/` — read-only evidence collectors.
- `docs/runbooks/` — ordered operational/troubleshooting procedures where interpretation matters.
- `templates/` — known-good starting files for creating something new.
- `dotfiles/` — conservative portable managed configuration.

Prefer an existing directory contract over creating a new top-level category.

## Safety checklist

Before committing a resource:

1. Remove credentials, tokens, private keys, internal-only addresses, and real customer/environment identifiers.
2. Use obvious placeholders such as `__HOSTNAME__`, `__SERVICE__`, or documentation-only addresses.
3. Keep diagnostics read-only; do not restart services, install packages, edit configuration, or dump likely-secret environments.
4. Make mutations explicit in runbooks/templates and include validation/rollback guidance where appropriate.
5. Avoid unsafe convenience defaults such as world-writable permissions or disabled security controls.

## Runbook standard

A runbook should normally contain:

1. Scope/symptoms.
2. Safety notes.
3. Read-only first checks.
4. Interpretation/decision path based on evidence.
5. Remediation options.
6. Validation.
7. Rollback considerations for changes.

Administration runbooks may be more procedural but should still explain what each stage proves.

## Template standard

Templates should:

- use portable defaults;
- contain no real secrets or identity values;
- use `__TOKEN__` placeholders consistently;
- prefer least privilege/non-root behavior where practical;
- include comments only where they materially help safe adaptation;
- work as individual files because `ror new` currently copies one template file at a time.

## Discovery integration

After adding a resource, decide whether it should be connected to a curated `ror need` topic in `lib/resources.sh`.

When adding a new topic:

- add it to `ror_need_topics`;
- add human aliases in `ror_need_canonical_topic`;
- add a purpose in `ror_need_description`;
- add useful first commands in `ror_need_commands`;
- add only real repository paths in `ror_need_resources`;
- extend smoke coverage for the topic/paths.

`ror need` is deterministic. Do not add fuzzy diagnosis or hidden inference to the relationship map.

## Documentation/index integration

Update the relevant indexes when the library changes:

- root `README.md` for user-facing capabilities;
- category README such as `docs/runbooks/README.md` or `templates/README.md`;
- `docs/architecture.md` when a repository contract changes;
- `tests/README.md` when validation behavior changes;
- `CHANGELOG.md` for capability-level changes and meaningful fixes.

## Validation checklist

At minimum:

```bash
bash tests/smoke/ror-smoke.sh
bash tests/smoke/dotfiles-smoke.sh
python3 tests/validate_markdown_links.py
```

Also use the appropriate syntax/lint tool for the resource type when available. GitHub Actions is the final repository-wide guardrail.

## Definition of done

A new resource is done when:

- the content is safe and portable;
- its path/name is understandable;
- it is indexed/discoverable;
- curated relationships are updated when useful;
- documentation and changelog reflect the capability change;
- automated validation passes.
