---
description: Deeper multi-agent review that also checks comments and type design
chain: parallel(review-skeptical, review-guidelines, review-tests, review-errors, review-comments, review-types) -> review-synthesize
---
This chain template ignores the body. Invoke it like:
- /review-deep current changes
- /review-deep last 5 commits
- /review-deep commit abc1234
- /review-deep src/server/auth.ts
