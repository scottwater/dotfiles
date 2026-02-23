---
name: loops-plan
description: Transform feature ideas/bugs into comprehensive implementation plans in docs/plans with research, flow analysis, and actionable phases.
---

# Loops Plan

Create a detailed implementation plan. No coding in this skill.

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

### 2. Plan Structure

Define:
- searchable title using conventional prefix: `feat|fix|refactor`
- filename with date + kebab + `-plan`
  - `YYYY-MM-DD-<type>-<descriptive-name>-plan.md`
- stakeholders and constraints
- scope boundaries and supporting artifacts

### 3. Inline Spec Flow Analysis

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

### 4. Inline Workflow Insight Analysis

Extract high-value decisions/constraints from gathered research and docs:
- finalized decisions and rationale
- non-negotiable constraints
- technical specs/config values
- superseded/outdated ideas to exclude

Filter aggressively:
- remove tangents and speculative options
- keep only actionable, current signals

### 5. Compose Comprehensive Plan

Always output detailed plan. Use this structure:

```markdown
---
title: [Issue Title]
type: [feat|fix|refactor]
date: YYYY-MM-DD
---

# [Issue Title]

## Overview

## Problem Statement

## Proposed Solution

## Technical Approach

### Architecture

### Implementation Phases

#### Phase 1: Foundation
- tasks
- success criteria
- estimated effort

#### Phase 2: Core Implementation
- tasks
- success criteria
- estimated effort

#### Phase 3: Polish & Optimization
- tasks
- success criteria
- estimated effort

## User Flows and Edge Cases
- flow map summary
- identified gaps
- explicit assumptions

## Alternative Approaches Considered

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

## Resource Requirements

## Future Considerations

## Documentation Plan

## References & Research

### Internal References
- `path/to/file:line`

### External References
- URL

### Related Work
- issue/PR/doc refs
```

### 6. Save Plan + Task Creation Hint

Write file:
- `docs/plans/YYYY-MM-DD-<type>-<descriptive-name>-plan.md`

Plan should stand alone. Include enough context for execution tooling (for example dex task conversion).

### 7. Final Review (Self-Contained)

Checklist before finish:
- title clear/searchable
- sections complete
- acceptance criteria measurable
- assumptions and edge cases explicit
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
