# Scripts

Executable utilities and diagnostic collectors. Use `ror run <path-under-scripts>` for complete utilities and `ror diagnose` / `ror collect` for named read-only diagnostic targets.

## Diagnostics

See [`diagnostics/README.md`](diagnostics/README.md) for the diagnostic safety contract and target index.

## Operational utilities

| Path | Purpose | Example |
|---|---|---|
| `system/port-process.sh` | Find local TCP/UDP listener/process ownership for a port | `ror run system/port-process.sh 8443` |
| `networking/cert-expiry.sh` | Show leaf certificate identity/expiry and return warning status near expiry | `ror run networking/cert-expiry.sh example.com:443 30` |
| `git/repo-health.sh` | Summarize branch, worktree, upstream and ahead/behind state without printing remote URLs | `ror run git/repo-health.sh .` |
| `kubernetes/workload-summary.sh` | Compact workload/pod summary for the current or named namespace | `ror run kubernetes/workload-summary.sh default` |

## Script contract

- One defined purpose per utility.
- Prefer read-only inspection unless mutation is the explicit purpose of the script.
- Never print likely-secret environment/config values merely for convenience.
- Fail clearly when a required tool or argument is missing.
- Use placeholders/examples rather than hard-coded environment identity.

See [`../docs/resource-authoring.md`](../docs/resource-authoring.md) for the full maintenance contract.
