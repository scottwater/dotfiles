---
description: Type-design review over an arbitrary change scope
subagent: type-design-analyzer
inheritContext: true
---
Review this target: $@

Resolve the review scope from the prompt using these defaults when helpful:
- "current changes" = staged + unstaged changes against HEAD
- "staged changes" = staged diff only
- "unstaged changes" = unstaged diff only
- "last N commits" = review the range `HEAD~N..HEAD`
- explicit commit, range, branch diff, file paths, or directories = use exactly what was requested

Start by restating the exact scope you chose.
If the request is ambiguous, choose the smallest reasonable scope and say what you assumed.

Only report type-design findings. If the reviewed scope does not add or materially change types, say so clearly.
