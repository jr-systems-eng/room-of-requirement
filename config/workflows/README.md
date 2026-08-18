# Workflow Metadata

`config/workflows/index.tsv` is the deterministic registry behind `ror workflow`.

The workflow layer is intentionally separate from `ror need`:

- `ror need` answers **what resources relate to this topic?**
- `ror diagnose` answers **what state is the system in?**
- `ror workflow` answers **what ordered procedure should I follow, and what would change if I explicitly apply it?**
- `ror run` executes one specific utility.

## Index format

```text
name|aliases(comma-separated)|mode|status|description|script
```

Allowed modes:

- `read-only` — performs only inspection/validation.
- `preparation` — builds an evidence-backed deployment/change plan but does not apply it.
- `plan-apply` — default invocation is non-mutating; `--apply` is required for the workflow's defined changes.

Allowed statuses:

- `experimental` — new workflow requiring field testing before broad trust.
- `stable` — field-tested workflow whose behavior/rollback contract is considered mature.
- `deprecated` — retained for compatibility but should not be selected for new work.

Phase 8 workflows intentionally start as `experimental`. A successful CI run proves repository integrity and deterministic test behavior; it does **not** replace field testing on representative systems.

## Runtime contract

Workflow scripts live under `workflows/` and are dispatched by the generic reader in `lib/workflows.sh`.

For `plan-apply` workflows:

1. default invocation must not mutate the target;
2. preflight evidence and the intended plan should be visible before changes;
3. mutation requires an explicit `--apply` supplied by the user;
4. validation runs after the change;
5. rollback guidance must be printed when a meaningful rollback exists;
6. the workflow must not broaden its scope beyond the operation described in the registry.

Workflow scripts must not silently install tools merely to satisfy their own prerequisites.

## Validation

```bash
python3 tests/validate_workflow_metadata.py
bash tests/smoke/workflow-smoke.sh
```

The metadata validator checks names/aliases, modes/statuses, safe repository-relative script paths, script existence/executable bits, and duplicate ownership.
