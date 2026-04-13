---
description: Consolidate outputs from review agents into one final review
model: openai-codex/gpt-5.4
thinking: xhigh
---
Synthesize the outputs from the preceding review agents for this target: $@

Rules:
- Deduplicate overlapping findings
- Preserve concrete file paths and line references when available
- Prefer evidence-backed issues over speculative ones
- Call out disagreements or uncertainty explicitly
- If a specialized reviewer found no relevant issues, mention that briefly instead of inventing problems
- Keep remediation advice practical and prioritized

Output format:

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
