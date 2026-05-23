---
name: loops-research
description: Conduct comprehensive codebase research, then synthesize into a dated research document with metadata.
---

# Loops Research

Use this skill for deep codebase research.

## Scope Guardrails

Primary mode: documentation of current state.

Unless user explicitly asks for critique/recommendations:
- do not suggest improvements
- do not perform root-cause analysis
- do not propose future enhancements
- do not critique architecture/quality
- describe what exists, where, how it works, and interactions

## Workflow

### 0. Intake

If query missing, ask:
- "What would you like to know more about in this codebase?"

Do not continue until scope is clear.

### 1. Read User-Mentioned Files First

If user mentions specific files/docs/tickets:
- read those files fully before broader research
- do this in main context
- no partial reads for these initial files

### 2. Decompose Research Question

Break request into composable areas:
- components and boundaries
- data/control flow
- config and integration points
- related docs/history

Identify what each research thread should cover.

### 3. Run Parallel Research Threads (Self-Contained)

Run these threads in parallel when possible.

#### Thread A: Locate relevant files
- Use `rg`/`find` for names, symbols, routes, feature keywords
- Group by implementation, tests, config, docs, entry points
- Output: structured file inventory

#### Thread B: Analyze implementation paths
- Read entry points and follow call chain
- Trace transformations and side effects
- Capture file:line evidence for each claim
- Output: behavior map (what happens, in order)

#### Thread C: Find similar patterns
- Search for analogous implementations elsewhere in repo
- Extract representative snippets and test patterns
- Capture where each pattern appears (`path:line`)
- Output: pattern catalog with concrete examples

### 4. Wait and Synthesize

Wait for all threads before synthesis.

Synthesis requirements:
- prioritize live code as source of truth
- use `docs/research/` as historical supplement
- include concrete file paths and line numbers
- connect cross-component behavior
- answer exact user question with evidence

### 5. Gather Metadata (Self-Contained)

Before writing output:

1. If the repo has a metadata helper (for example `scripts/spec_metadata.sh`), run it.
2. Otherwise gather metadata manually:
```bash
date -Iseconds
git rev-parse --short HEAD
git rev-parse --abbrev-ref HEAD
git config --get remote.origin.url
```

Filename pattern:
- with ticket: `docs/research/YYYY-MM-DD-ENG-XXXX-description.md`
- without ticket: `docs/research/YYYY-MM-DD-description.md`

### 6. Write Research Document

Create markdown doc with frontmatter and sections.

Template:

```markdown
---
date: [ISO datetime with timezone]
researcher: [name]
git_commit: [sha]
branch: [branch]
repository: [repo]
topic: "[user question]"
tags: [research, codebase, ...]
status: complete
last_updated: [YYYY-MM-DD]
last_updated_by: [name]
---

# Research: [Topic]

**Date**: ...
**Researcher**: ...
**Git Commit**: ...
**Branch**: ...
**Repository**: ...

## Research Question
[original query]

## Summary
[high-level answer]

## Detailed Findings
### [Area]
- What exists (`path/file.ext:line`)
- How it connects
- Current behavior details

## Code References
- `path/to/file:line` - description

## Architecture Documentation
[current patterns and conventions observed]

## Historical Context
[relevant prior docs]

## Related Research
[links/paths]

## Open Questions
[remaining unknowns]
```

### 7. Add GitHub Permalinks (When Applicable)

If branch/commit is suitable for stable links:
- gather repo owner/name
- generate permalinks using commit SHA
- replace plain local references with permalinks where useful

### 8. Follow-Up Updates

For follow-up questions:
- append to same document
- update `last_updated` and `last_updated_by`
- add `last_updated_note`
- add `## Follow-up Research [timestamp]`
- run additional research threads as needed

## Ordering Constraints

Always preserve order:
1. read user-mentioned files first
2. run and complete research threads
3. gather metadata
4. write document with real values (no placeholders)

## Output Quality Bar

- self-contained research artifact
- explicit evidence and references
- cross-component connections documented
- temporal context included
- no recommendations unless requested
