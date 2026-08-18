#!/usr/bin/env python3
from __future__ import annotations

from collections import defaultdict
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
ROOM = ROOT / "config" / "room"


def read_rows(name: str, columns: int) -> list[tuple[int, list[str]]]:
    path = ROOM / name
    rows: list[tuple[int, list[str]]] = []
    for lineno, raw in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        line = raw.strip()
        if not line or line.startswith("#"):
            continue
        parts = raw.split("|")
        if len(parts) != columns:
            raise ValueError(f"{path}:{lineno}: expected {columns} pipe-delimited fields, got {len(parts)}")
        rows.append((lineno, [part.strip() for part in parts]))
    return rows


def fail(message: str) -> None:
    print(f"ERROR: {message}", file=sys.stderr)
    raise SystemExit(1)


def main() -> None:
    try:
        topic_rows = read_rows("topics.tsv", 4)
        action_rows = read_rows("actions.tsv", 2)
        resource_rows = read_rows("resources.tsv", 4)
    except (OSError, ValueError) as exc:
        fail(str(exc))

    topics: dict[str, tuple[int, list[str], str, list[str]]] = {}
    names: dict[str, str] = {}

    for lineno, (topic, aliases_raw, description, related_raw) in topic_rows:
        if not topic or topic.lower() != topic or any(ch.isspace() for ch in topic):
            fail(f"topics.tsv:{lineno}: invalid canonical topic {topic!r}")
        if topic in topics:
            fail(f"topics.tsv:{lineno}: duplicate topic {topic!r}")
        if not description:
            fail(f"topics.tsv:{lineno}: topic {topic!r} has no description")

        aliases = [item for item in aliases_raw.split(",") if item]
        related = [item for item in related_raw.split(",") if item]
        topics[topic] = (lineno, aliases, description, related)

        for name in [topic, *aliases]:
            if name.lower() != name or any(ch.isspace() for ch in name):
                fail(f"topics.tsv:{lineno}: invalid topic/alias {name!r}")
            owner = names.get(name)
            if owner is not None:
                fail(f"topics.tsv:{lineno}: {name!r} is already owned by topic {owner!r}")
            names[name] = topic

    for topic, (lineno, _aliases, _description, related) in topics.items():
        for related_topic in related:
            if related_topic not in topics:
                fail(f"topics.tsv:{lineno}: topic {topic!r} relates to unknown topic {related_topic!r}")
            if related_topic == topic:
                fail(f"topics.tsv:{lineno}: topic {topic!r} cannot relate to itself")

    actions: dict[str, int] = defaultdict(int)
    for lineno, (topic, command) in action_rows:
        if topic not in topics:
            fail(f"actions.tsv:{lineno}: unknown topic {topic!r}")
        if not command:
            fail(f"actions.tsv:{lineno}: empty command for topic {topic!r}")
        actions[topic] += 1

    resources: dict[str, int] = defaultdict(int)
    seen_paths: set[tuple[str, str]] = set()
    for lineno, (topic, resource_type, path_raw, note) in resource_rows:
        if topic not in topics:
            fail(f"resources.tsv:{lineno}: unknown topic {topic!r}")
        if not resource_type or not note:
            fail(f"resources.tsv:{lineno}: resource type/note must not be empty")
        path = Path(path_raw)
        if path.is_absolute() or ".." in path.parts:
            fail(f"resources.tsv:{lineno}: unsafe/non-relative path {path_raw!r}")
        if not (ROOT / path).exists():
            fail(f"resources.tsv:{lineno}: missing repository path {path_raw!r}")
        key = (topic, path_raw)
        if key in seen_paths:
            fail(f"resources.tsv:{lineno}: duplicate resource {path_raw!r} for topic {topic!r}")
        seen_paths.add(key)
        resources[topic] += 1

    for topic in topics:
        if actions[topic] == 0:
            fail(f"topic {topic!r} has no action")
        if resources[topic] == 0:
            fail(f"topic {topic!r} has no resource")

    alias_count = len(names) - len(topics)
    print(
        f"Room metadata valid: {len(topics)} topics, {alias_count} aliases, "
        f"{sum(actions.values())} actions, {sum(resources.values())} resources"
    )


if __name__ == "__main__":
    main()
