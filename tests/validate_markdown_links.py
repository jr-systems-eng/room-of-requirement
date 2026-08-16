#!/usr/bin/env python3
"""Validate local Markdown links without making network requests."""

from __future__ import annotations

import re
import sys
from pathlib import Path
from urllib.parse import unquote, urlparse

ROOT = Path(__file__).resolve().parents[1]
LINK_RE = re.compile(r"(?<!!)\[[^\]]*\]\(([^)]+)\)")
SKIP_SCHEMES = {"http", "https", "mailto", "tel", "ftp"}


def local_target(source: Path, raw: str) -> Path | None:
    target = raw.strip().split(maxsplit=1)[0].strip("<>")
    if not target or target.startswith("#"):
        return None
    parsed = urlparse(target)
    if parsed.scheme in SKIP_SCHEMES or parsed.netloc:
        return None
    path = unquote(parsed.path)
    if not path:
        return None
    if path.startswith("/"):
        return ROOT / path.lstrip("/")
    return source.parent / path


def main() -> int:
    failures: list[str] = []
    for md in sorted(ROOT.rglob("*.md")):
        if ".git" in md.parts:
            continue
        text = md.read_text(encoding="utf-8")
        for match in LINK_RE.finditer(text):
            raw = match.group(1)
            target = local_target(md, raw)
            if target is None:
                continue
            if not target.exists():
                failures.append(f"{md.relative_to(ROOT)} -> {raw}")

    if failures:
        print("Broken local Markdown links:", file=sys.stderr)
        for failure in failures:
            print(f"  {failure}", file=sys.stderr)
        return 1

    print("Local Markdown links are valid.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
