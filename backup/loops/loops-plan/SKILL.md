---
name: loops-plan
description: Transform feature ideas/bugs into comprehensive implementation plans in docs/plans with research, flow analysis, and actionable phases.
---

# Loops Plan

Create a detailed implementation plan. No coding in this skill.

## Default Interaction Contract

This skill defaults to collaborative planning.

Do not jump directly to writing the final implementation plan unless the user explicitly asks for a one-shot draft (for example: "just draft it", "skip questions", "one-shot this", or "make reasonable assumptions and proceed").

The user should never need to say special phrases like "work back and forth with me" to get collaborative planning behavior.

For non-trivial requests, the default sequence is:
1. research
2. surface open questions and assumptions
3. present a concise outline
4. get user feedback or explicit permission to proceed
5. write and save the final plan

## One-Shot Exception

If the user explicitly requests speed over interaction:
- say you are proceeding in one-shot mode
- make reasonable assumptions
- include an `Assumptions Requiring Confirmation` section near the top of the plan
- still surface any critical blockers before continuing

**Note: current year 2026.** Use in dates and time-aware research.

## Input

Feature description, bug report, or improvement idea.

If missing, ask:
- "What would you like to plan?"

Do not continue without clear scope.

## Workflow

### 0. Idea Refinement

Check recent brainstorms first:
- scan `docs/brainstorms/*.md`
- relevance: semantic match + created within last 14 days
- if multiple: ask user which to use

If relevant brainstorm found:
- read it
- announce using it
- extract key decisions/chosen approach/open questions
- skip repeated ideation

If not found:
- run short clarification dialogue
- ask one question at a time
- focus on purpose, constraints, success criteria
- stop when clear or user says proceed

Capture planning signals during intake:
- user familiarity with codebase
- speed vs thoroughness intent
- topic risk (security/payments/external APIs)
- uncertainty level

### 1. Local Research (Self-Contained)

Run these research tracks in parallel where possible.

Keep research objective:
- capture current behavior, file locations, constraints, and existing patterns
- separate what exists now from proposed changes
- do not let a preferred solution bias the research findings

#### A) Codebase location scan (inline)

Goal: find where related code lives (without deep implementation analysis).

- use `rg`/`find` for feature keywords and synonyms
- collect implementation, tests, config, docs, and entry points
- group findings by purpose
- identify high-signal directories

Minimum output for this step:
- 5-15 likely relevant files
- related test files
- related config/docs paths

#### B) Institutional learnings scan (inline)

Search `docs/solutions/` using grep-first filtering:

1. Extract keywords from request (module, symptoms, component, tech terms)
2. Run targeted grep across frontmatter fields (`title`, `tags`, `module`, `component`)
3. Always read `docs/solutions/patterns/critical-patterns.md` when present
4. Read frontmatter of matched files first
5. Fully read only strongly relevant files

Prioritize learnings by:
- module match
- symptom/tag overlap
- severity (`critical`, `high` first)

### 1.5 Consolidate Research

Build findings set:
- concrete local file references (`path:line` when available)
- relevant learnings from `docs/solutions`
- external references (if used)
- related issues/PRs
- conventions to follow from `AGENTS.md`

### 2. Design Discussion (Mandatory Before Plan)

After research, first produce a short design discussion in the chat. This is required for non-trivial requests unless the user explicitly asks for a one-shot draft.

Include:
- current state (objective, codebase-backed)
- desired end state
- key constraints and non-negotiables
- open questions and implementation blockers
- explicit assumptions if information is missing
- candidate approaches only when there are meaningful tradeoffs

Rules:
- clear scope is not enough; if material design decisions remain implicit, surface them
- do not write the final plan yet
- ask one question at a time for blockers or high-risk tradeoffs
- if only lower-priority uncertainty remains, state assumptions explicitly and ask whether to proceed

For each major feature flow, map:
- happy path
- error paths
- cancellation/retry/resume
- first-time vs returning user
- permission/role variants
- state transitions
- integration boundaries

Identify gaps:
- unclear validation rules
- missing error handling behavior
- undefined success/failure criteria
- missing accessibility/security expectations
- unspecified timeouts/rate limits

Produce prioritized clarification questions:
1. Critical (implementation blocker/security/data risk)
2. Important (major UX/maintainability impact)
3. Nice-to-have (clarity improvements)

Extract high-value decisions/constraints from gathered research and docs:
- finalized decisions and rationale
- non-negotiable constraints
- technical specs/config values
- superseded/outdated ideas to exclude

Filter aggressively:
- remove tangents and speculative options
- keep only actionable, current signals

Before proceeding, present a short Design Summary in the chat with:
- current state
- desired end state
- finalized decisions
- open questions
- explicit assumptions

### 3. Structure Outline (Mandatory Before Final Plan)

Before writing the final plan, present a concise implementation outline in the chat.

Define:
- searchable title using conventional prefix: `feat|fix|refactor`
- filename with date + kebab + `-plan`
  - `YYYY-MM-DD-<type>-<descriptive-name>-plan.md`
- stakeholders and constraints
- scope boundaries and supporting artifacts
- proposed phases in implementation order
- ordering rationale
- dependencies or blockers
- validation/testing checkpoints between phases

Rules:
- prefer vertical slices over horizontal layer-by-layer phases
- each phase should end in something testable or otherwise verifiable
- avoid "all database, then all backend, then all frontend" plans unless the task truly requires it
- ask the user to confirm or adjust the outline before writing the final plan
- do not write the final plan until the outline has been reviewed or the user explicitly says to proceed

### 4. Compose Comprehensive Plan

After the design discussion and outline review are complete — or the user explicitly requests one-shot mode — write the detailed plan.

Use concise, execution-ready prose. Avoid filler and speculative tangents. Include sections conditionally when they are not relevant.

Use this structure:

```markdown
---
title: [Issue Title]
type: [feat|fix|refactor]
date: YYYY-MM-DD
---

# [Issue Title]

## Overview

## Current State

## Problem Statement

## Desired End State

## Proposed Solution

## Technical Approach

### Architecture

### Implementation Phases

#### Phase 1: Foundation
- tasks
- success criteria
- validation/checkpoint
- estimated effort

#### Phase 2: Core Implementation
- tasks
- success criteria
- validation/checkpoint
- estimated effort

#### Phase 3: Polish & Optimization
- tasks
- success criteria
- validation/checkpoint
- estimated effort

## User Flows and Edge Cases
- flow map summary
- identified gaps
- explicit assumptions

## Assumptions Requiring Confirmation
- ...

## Alternative Approaches Considered (if relevant)

## Acceptance Criteria

### Functional Requirements
- [ ] ...

### Non-Functional Requirements
- [ ] performance
- [ ] security
- [ ] accessibility

### Quality Gates
- [ ] tests
- [ ] docs
- [ ] review

## Success Metrics

## Dependencies & Prerequisites

## Risk Analysis & Mitigation

## Resource Requirements (if relevant)

## Future Considerations (if relevant)

## Documentation Plan

## References & Research

### Internal References
- `path/to/file:line`

### External References (if used)
- URL

### Related Work
- issue/PR/doc refs
```

### 5. Save Plan + Task Creation Hint

Write file:
- `docs/plans/YYYY-MM-DD-<type>-<descriptive-name>-plan.md`

Plan should stand alone. Include enough context for execution tooling (for example dex task conversion).

### 6. Final Review (Self-Contained)

Checklist before finish:
- title clear/searchable
- collaborative steps completed, or one-shot mode explicitly acknowledged
- outline reviewed by user, or user explicitly waived outline review
- sections complete
- acceptance criteria measurable
- assumptions and edge cases explicit
- `Assumptions Requiring Confirmation` included when needed
- multi-phase work uses vertical slices and includes validation checkpoints
- references valid
- examples include candidate filenames where useful
- add ERD mermaid diagram when introducing model/data changes

If user asks for refinement, run an inline refinement pass in this same skill:
- identify one critical improvement first
- auto-fix minor issues directly
- request approval for major structural/meaning changes
- update the same file, no side documents

## Post-Plan Options

Offer next step:
1. open/review plan
2. refine plan now (inline)
3. start implementation via `loops-work`
4. run targeted deep-dive via `loops-research`
5. create tracker issue (if user wants)

## Output Summary

Return:
- saved plan path
- 2-5 key decisions
- recommended next action

## Hard Rules

- do not implement code here
- prioritize clarity and execution readiness
- include concrete references
- prefer simpler approach where viable
