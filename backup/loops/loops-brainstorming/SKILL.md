---
name: loops-brainstorming
description: Explore requirements and approaches through collaborative dialogue before planning implementation. Use before loops-plan when requirements are ambiguous or tradeoffs are unclear.
---

# Brainstorming

Use this skill to decide WHAT to build before deciding HOW.

## Default Interaction Contract

This skill defaults to collaborative back-and-forth.

The user should never need to say special phrases like "work back and forth with me" to get interactive brainstorming behavior.

Do not skip directly to a brainstorm doc or a recommended approach unless the user explicitly asks for a one-shot draft.

## One-Shot Exception

If the user explicitly asks for a fast draft:
- say you are proceeding in one-shot mode
- make assumptions explicit
- include an `Assumptions to Validate` section in the brainstorm doc
- still pause if there is a critical blocker or major unresolved tradeoff

**Note: current year 2026.** Use when dating brainstorm docs.

## When to Use

Use when:
- requirements are vague/ambiguous
- multiple valid approaches exist
- tradeoffs need user alignment
- success criteria are unclear

Skip when:
- requirements are explicit and detailed
- straightforward bug fix with known path

If skip applies, suggest moving to `loops-plan`.

## Workflow

### Phase 1: Understand the Idea

1. Run a light repo scan for related patterns.
   - look for similar features
   - capture conventions from `AGENTS.md`

2. Run collaborative dialogue.
   - ask one question at a time
   - prefer multiple-choice when natural
   - start broad then narrow
   - validate assumptions explicitly
   - ask success criteria early

Key topics:
- purpose/problem
- users/context
- constraints/dependencies
- success criteria
- edge/error cases
- existing patterns to copy

Before moving to approaches, present a short understanding summary in the chat:
- problem to solve
- target users/context
- constraints
- success criteria
- open questions
- explicit assumptions

Ask the user to confirm or adjust this summary before moving to approaches, unless one-shot mode was explicitly requested.

Exit when idea is clear or user says proceed.

### Phase 2: Explore Approaches

Propose 2-3 concrete approaches.

For each approach include:
- short description (2-3 sentences)
- pros
- cons
- best-fit context

Lead with recommendation. Explain tradeoff. Apply YAGNI.

### Phase 3: Capture Design

Write file:
- `docs/brainstorms/YYYY-MM-DD-<topic>-brainstorm.md`

Ensure `docs/brainstorms/` exists.

Template:

```markdown
---
date: YYYY-MM-DD
topic: <kebab-case-topic>
---

# <Topic Title>

## What We're Building
[1-2 short paragraphs]

## Why This Approach
[brief tradeoff summary]

## Key Decisions
- [Decision 1]: [Rationale]
- [Decision 2]: [Rationale]

## Open Questions
- [Unresolved items for planning]

## Assumptions to Validate
- [Explicit assumptions that still need confirmation]

## Next Steps
- Move to `loops-plan` for implementation planning
```

### Phase 4: Optional Inline Refinement (Self-Contained)

If user wants refinement, run an inline review pass in this same skill:

1. Assess clarity, completeness, specificity, YAGNI
2. Auto-fix minor wording/formatting issues
3. Ask before substantive scope or meaning changes
4. Update the same brainstorm file directly

After up to 2 passes, recommend moving on.

### Phase 5: Handoff

Ask user what next:
1. refine brainstorm now (inline)
2. proceed to `loops-plan`
3. done for now

## Output Summary

Return concise closeout:

```text
Brainstorm complete.

Document: docs/brainstorms/YYYY-MM-DD-<topic>-brainstorm.md

Key decisions:
- ...
- ...

Next: run loops-plan when ready.
```

## Rules

- stay on WHAT, not HOW
- one question at a time
- default to simple path (YAGNI)
- keep sections concise (target 200-300 words max)
- pause for alignment after major section
- do not implement code in this skill

## Anti-Patterns

Avoid:
- many questions at once
- implementation deep dives
- unvalidated assumptions
- over-designed speculative scope
- long docs with low signal

## Planning Integration

When brainstorm doc exists, `loops-plan` should detect and use it.
If relevant brainstorm found, skip repeated ideation and start from decisions already captured.
