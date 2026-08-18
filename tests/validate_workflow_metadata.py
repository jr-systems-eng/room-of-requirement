#!/usr/bin/env python3
from __future__ import annotations

from pathlib import Path
import os
import sys

ROOT = Path(__file__).resolve().parents[1]
INDEX = ROOT / "config" / "workflows" / "index.tsv"
ALLOWED_MODES = {"read-only", "preparation", "plan-apply"}
ALLOWED_STATUSES = {"experimental", "stable", "deprecated"}


def fail(message: str) -> None:
    print(f"ERROR: {message}", file=sys.stderr)
    raise SystemExit(1)


def main() -> None:
    try:
        lines = INDEX.read_text(encoding="utf-8").splitlines()
    except OSError as exc:
        fail(str(exc))

    owners: dict[str, str] = {}
    workflows: dict[str, tuple[str, str, Path]] = {}

    for lineno, raw in enumerate(lines, 1):
        line = raw.strip()
        if not line or line.startswith("#"):
            continue
        parts = [part.strip() for part in raw.split("|")]
        if len(parts) != 6:
            fail(f"index.tsv:{lineno}: expected 6 pipe-delimited fields, got {len(parts)}")

        name, aliases_raw, mode, status, description, script_raw = parts
        if not name or name.lower() != name or any(ch.isspace() for ch in name):
            fail(f"index.tsv:{lineno}: invalid workflow name {name!r}")
        if name in workflows:
            fail(f"index.tsv:{lineno}: duplicate workflow {name!r}")
        if mode not in ALLOWED_MODES:
            fail(f"index.tsv:{lineno}: invalid mode {mode!r}")
        if status not in ALLOWED_STATUSES:
            fail(f"index.tsv:{lineno}: invalid status {status!r}")
        if not description:
            fail(f"index.tsv:{lineno}: workflow {name!r} has no description")

        aliases = [item for item in aliases_raw.split(",") if item]
        for token in [name, *aliases]:
            if token.lower() != token or any(ch.isspace() for ch in token):
                fail(f"index.tsv:{lineno}: invalid name/alias {token!r}")
            prior = owners.get(token)
            if prior is not None:
                fail(f"index.tsv:{lineno}: {token!r} is already owned by {prior!r}")
            owners[token] = name

        script = Path(script_raw)
        if script.is_absolute() or ".." in script.parts or not script.parts or script.parts[0] != "workflows":
            fail(f"index.tsv:{lineno}: unsafe workflow script path {script_raw!r}")
        resolved = ROOT / script
        if not resolved.is_file():
            fail(f"index.tsv:{lineno}: missing workflow script {script_raw!r}")
        if not os.access(resolved, os.X_OK):
            fail(f"index.tsv:{lineno}: workflow script is not executable: {script_raw!r}")
        if mode == "plan-apply" and "--apply" not in resolved.read_text(encoding="utf-8"):
            fail(f"index.tsv:{lineno}: plan-apply workflow does not expose an explicit --apply path")

        workflows[name] = (mode, status, script)

    if not workflows:
        fail("no workflows are registered")

    counts = {mode: sum(1 for value in workflows.values() if value[0] == mode) for mode in ALLOWED_MODES}
    alias_count = len(owners) - len(workflows)
    print(
        f"Workflow metadata valid: {len(workflows)} workflows, {alias_count} aliases, "
        f"modes={counts}"
    )


if __name__ == "__main__":
    main()
