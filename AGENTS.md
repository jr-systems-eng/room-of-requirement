# Room of Requirement — Agent Instructions

## Purpose
Portable Linux/system engineering knowledge and utility toolkit.

## Project conventions
- Read README.md and docs/resource-authoring.md.
- Reusable agent templates live in templates/agents/. This file is the instruction source for Room of Requirement. Read templates/agents/README.md before changing the kit.
- Preserve the need / diagnose / workflow / run operating model.
- Place new resources in their established categories.
- Keep utilities portable and dependencies minimal.
- Diagnostics must remain read-only unless explicitly classified otherwise.
- Prefer narrowly scoped inspection over broad sensitive-data collection.

## Quality and safety
- Provide meaningful errors and safe defaults.
- Never include real credentials or private environment identifiers.
- Include validation and rollback information for mutating workflows.
- Do not promote experimental workflows to stable without evidence.
- Follow existing repository tests and self-test conventions.
