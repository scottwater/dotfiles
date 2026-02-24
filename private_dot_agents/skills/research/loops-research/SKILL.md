---
name: loops-research
description: Run comprehensive codebase research by spawning parallel research agents and synthesizing findings with repository-specific metadata.
---

# Loops Research

Use this skill to perform deep codebase research tasks.

## Workflow

1. Follow the standard loops-research workflow and execute it end-to-end.
2. Execute research subagents in parallel.
3. Synthesize findings with exact file references.
4. Keep analysis descriptive unless user explicitly asks for recommendations.

## Required Supporting Skills

- `loops/codebase-locator`
- `loops/codebase-analyzer`
- `loops/codebase-pattern-finder`
- `loops/research-metadata`
- `loops/web-search-researcher`
- `loops/workflow-analyzer`
