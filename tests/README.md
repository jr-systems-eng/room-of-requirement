# Tests

Room of Requirement tests protect the portability and safety promises of the repository.

## Smoke tests

Run the CLI smoke suite with:

```bash
bash tests/smoke/ror-smoke.sh
```

The smoke suite checks core discovery, reference, package, diagnostic, and collection interfaces without intentionally changing system configuration.

## Markdown links

Validate local Markdown links with:

```bash
python3 tests/validate_markdown_links.py
```

Only local repository links are checked. External URLs are deliberately not fetched so validation remains deterministic and does not require internet access.

## CI

GitHub Actions additionally checks shell syntax, ShellCheck findings, YAML, JSON, PowerShell parsing, smoke tests, and secret scanning.
