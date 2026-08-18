# Tests

Room of Requirement tests protect portability, rollback, discovery, reuse, relationship integrity, and safety promises.

## CLI smoke tests

```bash
bash tests/smoke/ror-smoke.sh
```

The cross-platform smoke suite checks core discovery, package profiles, diagnostic/collection interfaces, template copying, dotfile read-only interfaces, and the Room relationship layer.

Phase 7 coverage verifies:

- metadata-backed `ror need` still resolves aliases and resources on Linux and Git Bash/Windows;
- output contains `Start here` and `Related rooms` sections;
- NFS, performance, Docker/container, and Kubernetes resources are discoverable;
- Docker/Kubernetes diagnostics degrade safely when their CLIs/servers are unavailable and still emit a `SUMMARY`;
- representative operational utilities can be invoked without mutating host state;
- every runtime resource path returned by the Room index exists.

## Room metadata integrity

```bash
python3 tests/validate_room_metadata.py
```

This validator checks:

- unique canonical topics and aliases;
- lowercase/single-token topic naming;
- valid related-room links;
- valid action/resource ownership;
- at least one action/resource per topic;
- repository-relative resource paths with no traversal;
- existence and uniqueness of resource paths per topic.

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

GitHub Actions runs Bash syntax, error-level ShellCheck, YAML/JSON validation, Room metadata integrity, local Markdown links, PowerShell parsing, Ubuntu/Windows CLI smoke tests, Ubuntu/Windows dotfile lifecycle tests, and full-history Gitleaks scanning.

See [Resource Authoring Guide](../docs/resource-authoring.md) for the definition-of-done checklist when adding new library content.
