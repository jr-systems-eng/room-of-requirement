# AI Agent Standards — Setup, Operation, and Repository Rollout

The **Agent Standards Kit** is a portable way to give coding agents durable repository instructions while keeping individual tasks bounded, reviewable, and inexpensive to run. This is the canonical operational guide; the [kit reference](../../templates/agents/README.md) describes each template in detail.

The kit **does not automatically orchestrate agents, run Git operations, sync Cursor workspaces, or grant approvals**. It supplies versioned instructions and task templates, plus a read-only audit. Humans or separately authorized workflows perform the requested actions.

## Feature and command map

| Feature | Entry point | Effect |
| --- | --- | --- |
| Discover agent resources | `ror need agents` | Read-only list of curated actions, templates, guide, and audit script |
| Search resource names | `ror find --type template agents` | Find templates |
| Create repository instructions | `ror new agents/project-AGENTS.md ./AGENTS.md` | Copies a template **only if the destination does not exist** |
| Start a bounded task | `ror new agents/work-order.md ./work-order.md` | Copies a work-order template; fill it and provide it to the agent |
| Record completion | `ror new agents/handoff.md ./handoff.md` | Copies a handoff template for a task |
| Inspect sibling repositories | `ror run git/audit-agent-standards.sh --root /path/to/repos` | Read-only status table |
| Require clean, tracked instructions | `ror run git/audit-agent-standards.sh --root /path/to/repos --strict` | Returns nonzero for included repositories needing attention |
| Exclude intentional exceptions | Add `--exclude fork-one,work-repo` | Skips those immediate child directories |

`ror run` supports the audit script directly; alternatively run `bash scripts/git/audit-agent-standards.sh ...` from the ROR clone. Neither method changes any scanned repository. The audit scans **immediate subdirectories** containing a Git worktree, not the whole filesystem or GitHub account.

## The three instruction layers

1. **Cursor User Rules** — personal cross-repository preferences such as clarity, short context, small diffs, security, and approval boundaries. Maintain these in Cursor's rules settings. They are not created by ROR and are not a replacement for repository rules.
2. **Team Rules**, if enabled by the organization — organization-level requirements. Do not assume a personal account has this capability.
3. **Repository instructions** — root or nested committed `AGENTS.md` and, where used, `.cursor/rules/*.mdc`. These travel with the repository and define authoritative docs, project-specific safety rules, validation, and completion.

A task-specific **work order** adds the objective, inclusion/exclusion boundaries, acceptance criteria, and dependencies. A **handoff** records results and closes that task. Neither substitutes for standing repository instructions. A project's more restrictive security or deployment rule still applies.

### Local versus Cloud Agent

Local agents can see the present local workspace, including uncommitted files in the opened repository. Cloud agents see the repository revision they actually checked out, which may be older than today's `main`. They cannot rely on a local untracked `AGENTS.md`. Publish the instructions in Git first, and check `git status --short --branch`, `git rev-parse --short HEAD`, and the expected base/head before cloud work. Do not assume starting a new chat refreshed the checkout. If a fast-forward update is explicitly authorized, use `git pull --ff-only` after checking local changes and branch.

## Initialize a new repository

1. Open **the intended Git repository**, not merely an adjacent folder in a multi-root workspace. Check `git rev-parse --show-toplevel` and `git status --short --branch`.
2. Read its README, existing instructions, build/test commands, and relevant architecture.
3. If a root `AGENTS.md` already exists, **edit and preserve it**; `ror new` must not overwrite it.
4. Otherwise, from the target repository root, run:

   ```bash
   ror new agents/project-AGENTS.md ./AGENTS.md
   ```

5. Replace **every** `__TOKEN__` with facts verified for that repository; remove the template's Adaptation section. In particular, specify authoritative docs, local invariants, credential rules, meaningful validation commands, deployment limits, and task completion boundaries.
6. Inspect the diff, run relevant checks, and separately authorize the commit/push/PR. A committed root `AGENTS.md` is essential for Cloud Agents.
7. Review and merge the PR via the repo's normal process. Refresh the checkout used by agents after merging.

Keep the shared template generic. Put hostnames, environment-specific facts, and special approval rules in the individual repository, not in ROR's public template. Do not put credentials or work-only material in personal repositories.

## Adopt standards in an existing repository

Perform an **audit first**, then compare any locally generated, untracked `AGENTS.md` with the target branch. It may contain useful project-specific instructions. Do not blindly regenerate or overwrite it.

- `MISSING`: no root instructions found.
- `LOCAL_ONLY`: file exists but Git does not track it; Cloud Agent clones will not inherit it.
- `MODIFIED`: tracked file differs locally (staged or unstaged); review before pulling.
- `TRACKED`: root file exists in Git, with no current local modifications.
- `+PLACEHOLDERS`: unresolved template tokens remain; resolve before considering the repository compliant.

The audit does **not** assert that an instruction file is correct, that CI passes, or that `main` is up to date. It only checks the tracked/local state of `AGENTS.md`. Use `git status`, review the file itself, and run project tests for deeper validation.

For a directory of sibling clones:

```bash
ror run git/audit-agent-standards.sh --root /path/to/repos
ror run git/audit-agent-standards.sh \
  --root /path/to/repos \
  --exclude upstream-fork,empty-project,work-vault \
  --strict
```

The audit prints one row per included repository and a final count. Exclusions are explicit directory names separated by commas; record your approved exceptions rather than pretending they are failures.

If a pull would collide with a locally untracked `AGENTS.md`, back it up **outside the checkout**, compare both versions, then decide what to combine. Avoid `git reset --hard`, force pushes, or mass file deletion as shortcuts.

## Cursor project layout and context control

A **standalone repository window** is best for focused tasks and unambiguous Git controls. A **multi-root workspace** is useful when a task must read multiple personal repositories; open the workspace file and verify the repo selector before Git actions. A workspace grouping is a local convenience, not a single Git repository or an authorization to change everything inside it.

Use a small initial read set: root `AGENTS.md`, README, one relevant design document, and only the files necessary for the task. Avoid scanning all repos, whole vaults, generated output, giant logs, or secrets. Keep task scope to one deliverable; ask for an explicit dependency when crossing repo boundaries. Always name the authoritative source of truth when two repos describe the same system.

## Daily agent execution protocol

1. **Inspect** repository, branch, head, worktree status, and the current `AGENTS.md`.
2. **Scope** one deliverable using a work order (fill `__TOKEN__` fields or include equivalent explicit instructions directly in the task).
3. **Discover** only relevant documentation and paths. Surface meaningful assumptions; don't run broad exploratory reads by default.
4. **Implement** inside the approved repository and task limits. Stop before unapproved deployments, secret exposure, destructive actions, financial cost, or commits/pushes if those remain reserved.
5. **Validate** with the smallest tests covering changed behavior. Capture commands and observed outcomes, including any tests not run.
6. **Review** the exact file list and `git diff --check`. Confirm existing project instructions and unrelated work remain intact.
7. **Handoff** with changed files, evidence, decisions, assumptions, blockers, outstanding approvals, and **one recommended next action left unstarted**.
8. **Publish** through a feature branch/PR only if that is included in the assignment. Merge and production deployment are distinct decisions.

An example compact work order:

```text
Task: Add a read-only configuration audit for one component
In scope: the component script, its unit test, and its README
Out of scope: other repos, live deployment, commits, and pushes
Acceptance: command reports state; missing dependency is explained; tests pass
Validation: bash -n script.sh; run the focused test
Stop: acceptance met, blocked, or new approval required
```

Use `ror new agents/work-order.md ./work-order.md` for the full form. A committed work-order file is not required for every small question; if you create one, choose a task-document destination consistent with the repository and remove temporary working copies when no longer needed. Use `ror new agents/handoff.md ./handoff.md` only where a written handoff is useful.

The kit's handoff states are `complete`, `ready-for-review`, and `blocked`. A team-specific multi-agent protocol can define other states; do not claim they are standard across all repositories.

## Review, PRs, and ongoing checks

- Put one coherent deliverable in a feature branch. Keep `main` stable.
- Require review of exact changed files, not just a summary from the agent. `git diff --check` detects whitespace issues but does not test behavior.
- Run project-specific validation (syntax, lint, unit/CI, security, link checking) as applicable.
- Never auto-merge just because a CI job is green. A reviewer approves changes and the authorized operator merges.
- Refresh local clones safely after merging: inspect status and branch, use `git pull --ff-only` on a clean target, and rerun the audit.
- Where a Git checkout is synchronized automatically by an editor/plugin, stop that sync or coordinate with it before branch switches or merges. Back up local-only data before removing tracked device-specific files.

### Troubleshooting

| Symptom | Explanation and first action |
| --- | --- |
| New agent ignores repository conventions | Check that `AGENTS.md` exists in **that** checkout and revision; confirm the right workspace root |
| Audit says `LOCAL_ONLY` | File is untracked; compare it, then publish via an authorized PR |
| Audit says `MODIFIED` | There are local edits; inspect `git diff -- AGENTS.md` and staged diff before pulling |
| `ror new` refuses a destination | Expected safety behavior; inspect/edit the existing file rather than overwrite |
| Multi-root IDE shows another repo's branch | Confirm `git -C /path/to/repo status --short --branch` before committing |
| Cloud checkout is stale | Check `HEAD` and branch/ref; request a bounded, safe update, never discard uncommitted work |
| Agent grows beyond scope or burns context | Stop, review the work order, limit reads and tools, and ask for a concise handoff |
| PR has a modify/delete conflict | Review both intents; use an isolated worktree and explicit resolution, not a blind web merge |

## New workstation / recovery

For a new machine, follow [Portable Workstation Setup](portable-workstation.md) to install ROR, configure Git credentials independently, and clone only authorized projects. Restore or recreate Cursor's local workspace files separately (they are not Git repositories). Apply global preferences through Cursor settings, not by placing sensitive content in public templates. Run `ror need agents` and the local audit, inspect exceptions, and verify the committed `AGENTS.md` in each selected project.

## References

- [Agent Standards Kit and instruction layers](../../templates/agents/README.md)
- [Project instructions template](../../templates/agents/project-AGENTS.md)
- [Work-order template](../../templates/agents/work-order.md)
- [Handoff template](../../templates/agents/handoff.md)
- [Read-only audit implementation](../../scripts/git/audit-agent-standards.sh)
- [Room discovery metadata](../../config/room/README.md)
- [Resource authoring and validation](../resource-authoring.md)
