---
description: Silent-failure and error-handling review over an arbitrary change scope
subagent: silent-failure-hunter
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

Focus on swallowed errors, misleading fallbacks, weak logging, and failure modes that will be hard to debug.
