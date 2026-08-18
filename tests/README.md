# Tests

Room of Requirement tests protect portability, rollback, discovery, reuse, relationship integrity, workflow contracts, and safety promises.

## Local self-test

```bash
ror self-test
```

`ror self-test` is the quickest local trust check. It is read-only and network-independent. It verifies the VERSION format, required core paths, Bash syntax for the CLI/libs/workflows, Room/workflow metadata when Python is available, and basic CLI/version/workflow dispatch.

It is intentionally lighter than the full CI matrix.

## CLI smoke tests

```bash
bash tests/smoke/ror-smoke.sh
```

The cross-platform smoke suite checks core discovery, package profiles, diagnostic/collection interfaces, template copying, dotfile read-only interfaces, operational Git utility behavior, and the Room relationship layer.

## Guided workflow smoke tests

```bash
bash tests/smoke/workflow-smoke.sh
```

The workflow suite runs on both Ubuntu and Windows and verifies:

- all Phase 8 workflows are registered and visibly `experimental`;
- `ror version`, `ror path workflows`, and workflow metadata paths;
- each workflow exposes help successfully;
- unknown workflows fail rather than silently succeeding;
- the NFS workflow defaults to a non-mutating plan and does not create/change its test mountpoint;
- Ansible inventory validation works against a deterministic `ansible-inventory` stub without managed-host connections;
- `ror self-test` succeeds.

CI deliberately does **not** invoke workflow `--apply` paths. Mutating workflow behavior must be field-tested on representative systems. This is a design boundary, not a missing test accidentally overlooked.

## External diagnostic stub tests

```bash
bash tests/smoke/external-diagnostics-smoke.sh
```

Docker/Kubernetes diagnostics depend on external CLIs/servers, so CI does **not** probe whatever daemon/cluster happens to be installed on a runner. The test instead places deterministic `docker` and `kubectl` stubs first on `PATH` and verifies collector parsing/summary behavior on both Ubuntu and Windows.

This keeps smoke tests fast, repeatable, and independent of vendor service availability while still exercising the collectors.

## Room metadata integrity

```bash
python3 tests/validate_room_metadata.py
```

This validator checks unique canonical topics/aliases, related-room links, action/resource ownership, minimum per-topic coverage, safe repository-relative paths, resource existence, and duplicates.

## Workflow metadata integrity

```bash
python3 tests/validate_workflow_metadata.py
```

This validator checks unique workflow names/aliases, allowed modes/statuses, non-empty descriptions, safe workflow implementation paths, file existence/executable bits, and that every `plan-apply` workflow exposes an explicit `--apply` path.

The Python metadata validators are stricter than the runtime readers by design.

## Dotfile lifecycle smoke tests

```bash
bash tests/smoke/dotfiles-smoke.sh
```

This suite uses a disposable `HOME`/state directory and validates install/restore round trips without touching the real user or CI-runner home configuration.

## Markdown links

```bash
python3 tests/validate_markdown_links.py
```

Only local repository links are checked; external URLs are not fetched.

## CI

GitHub Actions runs Bash syntax/error-level ShellCheck across `bin`, `lib`, `bootstrap`, `scripts`, `workflows`, and tests; YAML/JSON validation; Room/workflow metadata integrity; local Markdown links; PowerShell parsing; Ubuntu/Windows CLI smoke; deterministic external-diagnostic stubs; Ubuntu/Windows workflow smoke; Ubuntu/Windows dotfile lifecycle tests; and full-history Gitleaks scanning.

Passing CI establishes repository integrity for the encoded non-mutating behavior. It does not by itself promote an experimental workflow to stable.

See [Workflow Metadata](../config/workflows/README.md) and [Resource Authoring Guide](../docs/resource-authoring.md).
