# Guided Workflows

Workflows turn an established procedure into an inspectable sequence of preflight, plan, optional apply, validation, and rollback guidance.

They do **not** replace runbooks. Runbooks remain the detailed explanation/decision reference; workflows provide a constrained executable path for operations that are mature enough to encode.

## Phase 8 workflows

| Workflow | Mode | Status | Purpose |
|---|---|---|---|
| `nfs-client` | plan/apply | experimental | Configure and validate an NFSv4 client mount, optionally with guarded persistence. |
| `service-recovery` | plan/apply | experimental | Inspect, restart, and validate one systemd service without editing config. |
| `workstation` | plan/apply | experimental | Combine existing package-profile and managed-dotfile operations into one plan. |
| `ansible-inventory` | read-only | experimental | Validate/graph inventory without contacting managed hosts. |
| `certificate-deploy-prep` | preparation | experimental | Validate cert/key/chain and target backup considerations without deployment. |

List them with:

```bash
ror workflow list
```

## Safety model

`plan-apply` workflows are non-mutating by default. The user must add `--apply` to request changes. Workflows do not infer missing arguments or silently broaden their scope.

All Phase 8 workflows remain **experimental even when CI is green**. CI proves code/metadata/test integrity; representative field testing is required before promoting a workflow to `stable` in `config/workflows/index.tsv`.

Storage resizing/LVM growth is deliberately not automated in Phase 8. Continue using the LVM runbook until the workflow framework has earned more field confidence.

See [`../config/workflows/README.md`](../config/workflows/README.md) for the registry contract.
