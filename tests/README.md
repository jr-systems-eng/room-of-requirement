# Tests

Room of Requirement tests protect the portability, rollback, discovery, and safety promises of the repository.

## CLI smoke tests

Run the general CLI smoke suite with:

```bash
bash tests/smoke/ror-smoke.sh
```

It checks core discovery, reference, package-profile, diagnostic, collection, and read-only dotfile interfaces without intentionally changing system configuration.

Phase 5 smoke coverage also verifies:

- curated `ror need` topic listing;
- topic aliasing such as `certificate` -> `tls`;
- expected related-resource output for curated topics;
- the package-profile list line structure;
- portable `SUMMARY` sections from DNS and Java diagnostics.

## Dotfile lifecycle smoke tests

Run the managed-dotfile round-trip suite with:

```bash
bash tests/smoke/dotfiles-smoke.sh
```

This suite creates a disposable temporary `HOME` and state directory, then verifies that Bash/Readline, Git, and tmux managed fragments can be installed and restored safely. It checks that:

- existing host files receive the expected marked include/source blocks;
- managed fragments match the repository sources;
- rollback restores original host files exactly;
- managed files that did not exist before installation are removed on restore;
- backup snapshots remain discoverable after rollback.

The test never intentionally modifies the real user or CI-runner home configuration.

## Markdown links

Validate local Markdown links with:

```bash
python3 tests/validate_markdown_links.py
```

Only local repository links are checked. External URLs are deliberately not fetched so validation remains deterministic and does not require internet access.

## CI

GitHub Actions additionally checks shell syntax, error-level ShellCheck findings, YAML, JSON, PowerShell parsing, Ubuntu/Windows CLI smoke tests, Ubuntu/Windows dotfile lifecycle tests, and full-history secret scanning.
