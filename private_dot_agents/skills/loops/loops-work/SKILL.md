---
name: loops-work
description: Execute a plan/spec/todo to completion with task tracking, incremental validation, and quality gates.
---

# Loops Work

Execute work plans fast, safely, end-to-end.

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
3. implement with existing conventions
4. add/update tests
5. run relevant tests immediately
6. mark completed
7. evaluate incremental commit
8. update source plan checkboxes (`- [ ]` => `- [x]`)

### Incremental Commit Rules

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
- UI parity artifacts captured if applicable

## Key Principles

- clarify once, then execute
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
- open risks/blockers (if any)
- next concrete step
