---
name: loops-review
description: Run comprehensive review for a target change/request, defaulting to multi-agent review when useful.
---

# Loops Review

Use this skill for deep review of code/plan/request.

## Input

Review target/question.

If missing, ask:
- "What should I review?"

## Workflow

### 1. Scope Review Target

Collect:
- explicit files/components mentioned
- recent changes (`git diff HEAD`, `git diff --staged`)
- related files needed for context

### 2. Choose Review Mode (Self-Contained)

Default: multi-agent review via `counselors` CLI (if installed and configured).

Fallback: single-agent structured review when counselors is unavailable.

### 3. Build Review Prompt

Prompt should contain:
- exact user question
- target files (`@path` references)
- change summary
- explicit asks: risks, regressions, tradeoffs, alternatives

### 4. Run Review

#### Multi-agent path (preferred)

1. Discover available reviewers:
```bash
counselors ls
counselors groups ls
```
2. Show full list to user and confirm selected agents/group
3. Create run folder in project (e.g. `agents/counselors/<timestamp>-<slug>/`)
4. Write `prompt.md` there
5. Dispatch:
```bash
counselors run -f agents/counselors/<timestamp>-<slug>/prompt.md --tools <comma-separated-ids> --json
```
6. Parse manifest JSON and read each output file
7. Track failures separately (stderr files, empty outputs)

#### Single-agent fallback

Perform direct structured review yourself using same rubric and output format below.

### 5. Synthesize

Return:
- consensus findings
- disagreements
- key risks
- blind spots
- recommended next action

### 6. Optional Follow-On

Offer top 2-3 remediation actions.

## Output Format

```markdown
## Review Findings

### Critical
- ...

### High
- ...

### Medium
- ...

### Low
- ...

### Open Questions
- ...

### Recommendation
- ...
```

## Rules

- findings first; summary second
- include concrete file references where possible
- do not hide tool failures; report them
