# __PROJECT_NAME__ — Agent Instructions

## Adaptation

Copy this file to the destination repository root as `AGENTS.md`.

```bash
ror new agents/project-AGENTS.md ./AGENTS.md
```

Replace every `__TOKEN__`, then delete this section. The destination file is that repository's standing agent instructions. Room of Requirement keeps the kit usage guide at `templates/agents/README.md`.

## Purpose

__ONE_SENTENCE_PURPOSE__

## Authoritative documentation

Read these before changing the project:

- `__PRIMARY_DOC__`
- `__SECONDARY_DOC__`

Project facts live in those documents. This file records how agents work in this repository.

## Engineering conventions

- __CONVENTION__
- Prefer this repository's existing structure, names, and patterns.
- Keep each change inside the requested task.

## Scope and security

- Work inside this repository unless the current task names another repository.
- __SCOPE_LIMIT__
- Keep credentials, private keys, tokens, and secrets out of files, commits, logs, and handoffs.
- Use documented sources for hostnames, addresses, and topology. Mark an undocumented value as unknown.
- __SECURITY_RESTRICTION__

## Validation

- __VALIDATION_COMMAND__
- Run the checks that cover the files this task changes.
- Report each command and the result observed.

## Git and approval boundaries

- Commit, push, open a pull request, or rewrite history when the current task requests that action.
- Deploy, delete data, expose a service, or change shared infrastructure when the current task authorizes that action.
- Continue through work this task and these instructions already authorize.
- __PROJECT_APPROVAL_BOUNDARY__
- Stop and ask when the next step needs an approval this task has not granted, or when it leaves the authorized scope.

## Completion

- Stop when the task acceptance criteria are met, or when a stop condition in the active work order is met.
- Report the files changed, the validation that was run, decisions, assumptions, blockers, and any approval still open.
- State one recommended next action and leave it unstarted.
- Leave the completed task closed until a new request or work order authorizes more work.
