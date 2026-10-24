# Work Order __TASK_ID__

## Adaptation

Include this file with the task request. Replace every `__TOKEN__`, then delete this section. The repository `AGENTS.md` remains the standing instruction file.

## Task

- **Task ID:** __TASK_ID__
- **Owner:** __OWNER__
- **Repository:** __REPOSITORY__
- **Objective:** __OBJECTIVE__

## In scope

- __IN_SCOPE_ITEM__

## Out of scope

- __OUT_OF_SCOPE_ITEM__
- Any new task after this work order's completion checkpoint

## Acceptance criteria

- [ ] __ACCEPTANCE_CRITERION__

## Deliverables

- __DELIVERABLE__

## Required validation

- __VALIDATION_COMMAND__
- Report each command and the result observed.

## Approval dependencies

- __APPROVAL_DEPENDENCY_OR_NONE__

Continue through every step this order and the repository instructions already authorize. An open dependency holds only the step that depends on it.

## Stop conditions

Stop and write a handoff when any of these is true:

- The acceptance criteria are met.
- An approval dependency for the next step is still open.
- The next step is outside the in-scope list.
- A blocker cannot be resolved inside this order.

The completion checkpoint closes this task. A later task starts from a new request or work order.
