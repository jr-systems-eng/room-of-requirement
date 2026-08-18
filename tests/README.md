# Tests

Room of Requirement tests protect portability, rollback, discovery, reuse, relationship integrity, and safety promises.

## CLI smoke tests

```bash
bash tests/smoke/ror-smoke.sh
```

The cross-platform smoke suite checks core discovery, package profiles, diagnostic/collection interfaces, template copying, dotfile read-only interfaces, operational Git utility behavior, and the Room relationship layer.

Phase 7 coverage verifies metadata-backed `ror need`, Start-here/Related-room output, NFS/performance/Docker/Kubernetes discoverability, representative template copies, collection output, and runtime resource-path integrity.

## External diagnostic stub tests

```bash
bash tests/smoke/external-diagnostics-smoke.sh
```

Docker/Kubernetes diagnostics depend on external CLIs/servers, so CI does **not** probe whatever daemon/cluster happens to be installed on a runner. The test instead places deterministic `docker` and `kubectl` stubs first on `PATH` and verifies collector parsing/summary behavior on both Ubuntu and Windows.

This keeps smoke tests fast, repeatable, and independent of vendor service availability while still exercising the new collectors.

## Room metadata integrity

```bash
python3 tests/validate_room_metadata.py
```

This validator checks unique canonical topics/aliases, related-room links, action/resource ownership, minimum per-topic coverage, safe repository-relative paths, resource existence, and duplicates.

The Python validator is stricter than the runtime reader by design.

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

GitHub Actions runs Bash syntax, error-level ShellCheck, YAML/JSON validation, Room metadata integrity, local Markdown links, PowerShell parsing, Ubuntu/Windows CLI smoke tests, deterministic external-diagnostic stub tests, Ubuntu/Windows dotfile lifecycle tests, and full-history Gitleaks scanning.

See [Resource Authoring Guide](../docs/resource-authoring.md) for the definition-of-done checklist when adding new library content.
