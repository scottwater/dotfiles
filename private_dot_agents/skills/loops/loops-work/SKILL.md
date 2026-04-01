---
name: loops-work
description: Execute a plan/spec/todo to completion with task tracking, incremental validation, and quality gates.
---

# Loops Work

Execute work plans fast, safely, end-to-end.

## Default Execution Contract

This skill defaults to incremental execution with explicit checkpoints.

Do not attempt to execute the entire plan in one uninterrupted pass unless the work is trivial or the user explicitly asks for that style.

For non-trivial work, the default sequence is:
1. confirm the next slice of work
2. read the relevant code and plan references
3. implement one vertical slice
4. run validation immediately
5. review the actual diff
6. update task tracking and plan state
7. continue to the next slice

## Input

Plan/spec/todo doc path.

If input missing or unclear, ask once before starting.

## Workflow

### Phase 1: Quick Start

1. Read plan fully.
- follow links/references in plan
- ask clarifying questions early

2. Choose work mode (self-contained).
- if already on feature branch: ask continue vs new branch
- if on default branch: require explicit confirmation before committing there

3. Convert plan into actionable tasks.
- use `dex` for non-trivial scope when available
- fallback: explicit markdown checklist in plan/session notes
- capture dependencies and priority
- include testing/quality tasks

Dex quick commands:
```bash
dex create "<task name>" --description "<context + acceptance criteria>"
dex list --ready
dex show <id> --full
dex complete <id> --result "<verified outcome>" --commit <sha>
```

### Phase 2: Execute Loop

For each task:
1. mark in progress
2. read referenced code/patterns
3. read surrounding implementation enough to understand the change in context
4. implement with existing conventions
5. prefer vertical slices over horizontal layer-by-layer execution
6. add/update tests
7. run the smallest meaningful validation step immediately
8. confirm the slice behaves as expected before moving on
9. mark completed
10. evaluate incremental commit
11. update source plan checkboxes (`- [ ]` => `- [x]`) and note any approved deviations

### Incremental Commit Rules

Prefer vertical slices over horizontal layer-by-layer execution.

Avoid doing all database work, then all backend work, then all frontend work unless the plan or architecture truly requires it.

Each slice should end in something testable, reviewable, or otherwise verifiable.

Commit when:
- logical unit complete
- tests pass
- context switch incoming
- risky change boundary reached

Do not commit when:
- partial/WIP unit
- failing tests
- scaffolding-only noise

Commit style:
- conventional commits
- stage related files only (avoid `git add .`)

## Plan Drift Rules

If implementation reveals the plan is materially wrong, incomplete, or unsafe:
- stop before continuing deeper
- surface the mismatch clearly
- propose a corrected next step
- update the source plan or task list when appropriate
- ask the user before making major design or scope changes

Do not silently improvise around major plan defects.

### Phase 3: Quality Gates

Before handoff:
- run full relevant test suite
- run repo lint/format checks
- fix regressions immediately
- confirm no outstanding critical warnings

Optional for high-risk/complex work:
- run multi-agent review via `counselors` CLI when available
- address critical findings before final handoff

### Phase 4: Final Validation

Confirm:
- all planned tasks done
- dex tasks complete (if used)
- tests/lint passing
- implementation matches plan intent
- actual diff reviewed for correctness, unintended changes, and adherence to existing patterns
- any plan deviations are documented and reflected in the source plan/task list
- UI parity artifacts captured if applicable
- do not rely on tests alone as proof of correctness for sensitive changes

## Key Principles

- clarify once, then execute
- do not rely on the plan alone; read and understand the actual code being changed
- treat the plan as a tactical guide, not a substitute for code review
- self-review important diffs before handoff
- follow existing patterns, avoid reinvention
- test continuously, not only at end
- ship complete slices, avoid 80% states

## Pitfalls to Avoid

- analysis paralysis
- skipping clarifications
- ignoring plan references
- batch testing at end
- stale task tracking

## Output

Report:
- what shipped
- tests/checks run
- plan deviations made during implementation
- open risks/blockers (if any)
- next concrete step
