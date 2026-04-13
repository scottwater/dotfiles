---
description: Multi-agent code review using skeptical, guideline, test, and error-handling reviewers
chain: parallel(review-skeptical, review-guidelines, review-tests, review-errors) -> review-synthesize
---
This chain template ignores the body. Invoke it like:
- /review-agents current changes
- /review-agents staged changes
- /review-agents last 5 commits
- /review-agents branch diff vs main
