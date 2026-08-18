# Room Metadata

The files in this directory are the deterministic knowledge graph behind `ror need`.

They intentionally use a simple pipe-delimited text format rather than YAML/JSON parsing at runtime. The CLI can therefore read the relationship data with ordinary Bash while CI performs stricter structural validation with Python.

## `topics.tsv`

```text
topic|aliases(comma-separated)|description|related topics(comma-separated)
```

- Canonical topics and aliases are lowercase single tokens.
- An alias may belong to only one topic.
- Related topics must name another canonical topic.
- Relationships are navigational, not claims of causality.

## `actions.tsv`

```text
topic|command
```

Actions are ordered. The first action for a topic is displayed as **Start here**; remaining actions are displayed as follow-ups.

Commands are examples/instructions. `ror need` prints them; it does not execute them automatically.

## `resources.tsv`

```text
topic|type|repository-relative path|note
```

Every path must exist in the repository. CI validates this so renamed/deleted resources cannot silently disappear from a Room.

## Runtime contract

`lib/resources.sh` is the generic reader. Topic knowledge should live here in metadata rather than growing new topic-specific shell `case` statements.

`ror need` remains deterministic and read-only. It performs no fuzzy diagnosis and no hidden ranking based on host state.

## Validation

```bash
python3 tests/validate_room_metadata.py
```

The validator checks topic/alias uniqueness, related-topic references, action/resource ownership, relative-safe resource paths, missing files, duplicates, and minimum topic coverage.

See [`../../docs/resource-authoring.md`](../../docs/resource-authoring.md) before adding or changing Room metadata.
