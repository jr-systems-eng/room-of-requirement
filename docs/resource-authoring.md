# Resource Authoring Guide

This guide defines the maintenance checklist for adding reusable material to Room of Requirement.

The goal is to keep the repository portable, discoverable, safe, and internally consistent as it grows.

## Choose the correct resource type

- `cheat-sheets/` — concise reference material for remembering commands/concepts.
- `snippets/` — short copy/paste fragments.
- `scripts/` — executable utilities with one defined purpose.
- `scripts/diagnostics/` — read-only evidence collectors.
- `docs/runbooks/` — detailed operational/troubleshooting procedures where interpretation matters.
- `workflows/` — constrained guided procedures whose preflight/change/validation boundaries are safe enough to encode.
- `templates/` — known-good starting files for creating something new.
- `dotfiles/` — conservative portable managed configuration.
- `config/room/` — deterministic topic/action/resource/relationship metadata for `ror need`.
- `config/workflows/` — deterministic registry/maturity metadata for `ror workflow`.

Prefer an existing directory contract over creating a new top-level category.

## Safety checklist

Before committing a resource:

1. Remove credentials, tokens, private keys, internal-only addresses, and real customer/environment identifiers.
2. Use obvious placeholders such as `__HOSTNAME__`, `__SERVICE__`, or documentation-only addresses.
3. Keep diagnostics read-only; do not restart services, install packages, edit configuration, mutate workloads, or dump likely-secret environments.
4. Make mutations explicit in runbooks/templates/workflows and include validation/rollback guidance where appropriate.
5. Avoid unsafe convenience defaults such as world-writable permissions or disabled security controls.
6. Treat tool-specific inspection surfaces as potentially secret-bearing. Examples include process/container environments, raw kubeconfig, Kubernetes Secrets, credential-bearing Git remote URLs, and systemd unit environments.
7. Do not promote an experimental workflow to stable based only on CI; record representative field testing first.

## Diagnostic standard

A diagnostic should normally:

- print enough raw evidence to support its observations;
- remain read-only with respect to host/workload configuration;
- tolerate missing optional tools and say what was skipped;
- end with a conservative `SUMMARY` when direct evidence supports useful observations;
- avoid claiming a root cause from weak signals;
- avoid broad inspection commands when a narrower command avoids exposing secrets.

Ordinary connection/API-read tests are allowed when they are the diagnostic purpose.

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

## Workflow standard

A workflow is appropriate only when the operation is constrained enough that ROR can make the plan and mutation boundary explicit without pretending to understand more than it does.

Every workflow must be registered in `config/workflows/index.tsv` with a mode/status/description/script path.

### `read-only`

- may run inspection/validation immediately;
- must not contain a hidden mutation path;
- should say explicitly that no changes were made.

### `preparation`

- may inspect local/remote state needed to prepare a change;
- must stop before deployment/configuration mutation;
- should identify backup, ownership, permissions, reload/restart, or other operator decisions still required.

### `plan-apply`

Default invocation must be non-mutating. The workflow must:

1. collect preflight evidence;
2. surface blocking findings clearly;
3. print the exact intended change sequence;
4. require the literal `--apply` flag for mutation;
5. refuse apply if blocking preflight checks fail;
6. validate the result after mutation;
7. print concrete rollback guidance when meaningful;
8. avoid silently installing missing prerequisites;
9. limit changes to the operation named in the registry.

If the safe apply/rollback contract is unclear, keep the capability as a runbook instead of creating a workflow.

### Workflow maturity

New workflows normally start `experimental`.

Promote to `stable` only after representative field use has exercised successful apply, expected failure paths, validation, rollback/recovery, and platform-specific behavior relevant to the workflow's supported scope. CI success is necessary but insufficient.

Validate workflow metadata with:

```bash
python3 tests/validate_workflow_metadata.py
```

## Template standard

Templates should:

- use portable defaults;
- contain no real secrets or identity values;
- use `__TOKEN__` placeholders consistently;
- prefer least privilege/non-root behavior where practical;
- include comments only where they materially help safe adaptation;
- work as individual files because `ror new` currently copies one template file at a time.

## Room metadata integration

Topic knowledge lives under [`../config/room/`](../config/room/), not in topic-specific shell `case` statements.

When adding or changing a curated Room:

- update `config/room/topics.tsv` for canonical names, aliases, descriptions, and related rooms;
- update `config/room/actions.tsv` for ordered first/follow-up commands;
- update `config/room/resources.tsv` for repository resources, including workflows when relevant;
- use only canonical topic names in related-room/action/resource ownership fields;
- add only repository-relative resource paths that already exist;
- keep relationships navigational rather than implying causality;
- extend smoke coverage when a capability deserves explicit behavioral protection.

The first action for a topic is displayed as **Start here**. Related rooms are navigation hints only.

`ror need` remains deterministic. Do not add fuzzy diagnosis, automatic execution, or hidden ranking to this layer.

Validate metadata with:

```bash
python3 tests/validate_room_metadata.py
```

## Documentation/index integration

Update the relevant indexes when the library changes:

- root `README.md` for user-facing capabilities;
- category README such as `scripts/README.md`, `workflows/README.md`, `docs/runbooks/README.md`, or `templates/README.md`;
- `config/room/README.md` / `config/workflows/README.md` when metadata contracts change;
- `docs/architecture.md` when a repository contract changes;
- `tests/README.md` when validation behavior changes;
- `CHANGELOG.md` for capability-level changes and meaningful fixes.

## Validation checklist

At minimum:

```bash
ror self-test
bash tests/smoke/ror-smoke.sh
bash tests/smoke/workflow-smoke.sh
bash tests/smoke/dotfiles-smoke.sh
python3 tests/validate_room_metadata.py
python3 tests/validate_workflow_metadata.py
python3 tests/validate_markdown_links.py
```

Also use the appropriate syntax/lint tool for the resource type when available. GitHub Actions is the repository-wide guardrail, but mutating workflow paths require field testing beyond CI.

## Definition of done

A new resource/capability is done when:

- the content is safe and portable;
- its path/name is understandable;
- it is indexed/discoverable;
- Room/workflow metadata are updated when relevant;
- documentation and changelog reflect the capability change;
- automated validation passes;
- any workflow apply path remains experimental until representative field testing justifies promotion.
