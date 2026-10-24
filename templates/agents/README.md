# Agent Standards Kit

Portable starting points for AI agent work in a repository. Copy a template into the destination project, replace every `__TOKEN__`, and maintain the result there.

`ror new` copies one file and leaves every `__TOKEN__` unchanged. The files use placeholders in place of project names, owners, and paths.

## When to use each template

| Template | Copy it when | Destination |
|---|---|---|
| [`project-AGENTS.md`](project-AGENTS.md) | The repository needs standing agent instructions | Repository root, saved as `AGENTS.md` |
| [`work-order.md`](work-order.md) | One task needs an owner, scope, acceptance criteria, and stop conditions | A task document included with that request |
| [`handoff.md`](handoff.md) | A task is stopping and needs evidence, decisions, and an explicit handoff state | A task record written at the checkpoint |

`AGENTS.md` is standing instruction. A work order bounds one task. A handoff closes that task.

Cursor loads `AGENTS.md` and [`.cursor/rules/*.mdc`](https://cursor.com/docs/rules) as instructions. Include a work order or handoff in the request that needs it. A later task starts when a new request authorizes it.

This repository stores the project template as `project-AGENTS.md`. Cursor treats a nested file named `AGENTS.md` as instructions for that directory, which would compete with this repository's root `AGENTS.md`. Save the copy at the destination root as `AGENTS.md`.

## Commands

```bash
ror new agents/project-AGENTS.md ./AGENTS.md
ror new agents/work-order.md ./work-order.md
ror new agents/handoff.md ./handoff.md
```

Replace every `__TOKEN__`, then delete the template's Adaptation section. Further template rules are in [Templates](../README.md) and the [Resource Authoring Guide](../../docs/resource-authoring.md).

## Instruction layers

Keep each kind of instruction in one place.

| Layer | Where it lives | What belongs there |
|---|---|---|
| User Rules | Cursor **Customize → Rules** | Personal preferences used across repositories: communication, individual workflow, and other cross-project habits |
| Team Rules | Cursor team dashboard, on Team and Enterprise plans | Organization standards for that team's repositories |
| Repository instructions | Committed root or nested `AGENTS.md`, and committed `.cursor/rules/*.mdc` | This repository's purpose, conventions, scope, validation, and approval boundaries |

User Rules are account preferences. Repository instructions travel with the project. Team Rules, when a team enables them, are merged ahead of Project Rules and User Rules. [Cursor's rules documentation](https://cursor.com/docs/rules) gives the conflict order as Team Rules, then Project Rules, then User Rules.

Put a personal standard in User Rules. Add it to a repository when that repository needs a stricter or more specific version. Point `AGENTS.md` at the project's README and other authoritative docs for project facts.

Nested `AGENTS.md` files combine with their parent directories. On a conflict, the file closer to the work applies. Add a nested file for instructions that apply only inside that directory.

## Local Agent and Cloud Agent

| Instruction | Local Agent | Cloud Agent |
|---|---|---|
| User Rules | Included for the account | Included for Cloud Agent sessions from that account |
| Team Rules | Included when enabled for the account | Included when enabled for the account |
| Committed `AGENTS.md` and `.cursor/rules/*.mdc` | Included from the workspace | Included from the revision the Cloud Agent checks out |
| Uncommitted project files | Included from the local workspace | Included after the change is committed and that revision is checked out |
| Machine-local rule files outside the repository | Available on that machine | Left on the machine; a managed Cloud Agent checkout contains the repository revision |

[Cloud Agent best practices](https://cursor.com/docs/cloud-agent/best-practices) describe those three rule levels: user rules in Cursor Settings, team rules from the dashboard, and repo rules committed as `.cursor/rules/*.mdc`. Commit the `AGENTS.md` a Cloud Agent should follow. Personal skills can be synced separately. This kit is a set of templates.

## Extending a copy

After `ror new`, the destination file belongs to that project.

- Fill the placeholders with that project's facts.
- Add short, project-specific bullets in the copied file.
- Link to the project's authoritative document for procedures, architecture, and domain rules.
- Keep this usage guide in Room of Requirement. The destination keeps its adapted file.
- Keep another project's roles, milestones, and approval gates in that project. Write a gate into the destination only when this repository uses that rule.
- Change the shared shape in `templates/agents/` when later copies should gain the same section. Update existing projects in a separate, explicit change.
- Let a work order narrow the current task while repository safety rules and User Rules still apply.
- Record what happened in the handoff. Standing instructions stay in `AGENTS.md` and User Rules.

## Bounded completion

Carry out the work the current request, the active work order, and repository instructions already authorize.

Stop at the work order's completion checkpoint. Write a handoff when the task asked for one. State one recommended next action, and leave that action unstarted. The next task begins when a new request or work order authorizes it.

Pause inside an authorized task for a named approval dependency, a listed stop condition, or a step outside the in-scope list.
