---
description: Create git commits following story-driven guidelines using conversation context
---

# Commit Changes with Guidelines

You are tasked with creating git commits that follow story-driven commit guidelines.

## Process

### 1. Understand the Context

- Are we working on a specific bead? If so, review the conversation history to understand what was accomplished during this session.
- Check the current branch name and see if it maps to a card in linear (always scott/ + 3 letters like AUD and then a number with some optional description)

If either of these exist, make sure you understand the context and use it to inform your commit decisions.

### 2. Understand What Changed

Run these commands in parallel to gather information:
- `git status` - See all modified, untracked, and staged files
- `git diff` - View unstaged changes in detail
- `git diff --staged` - View already-staged changes
- `git log --oneline -n 5` - Review recent commit style

Analyze the changes to understand:
- What features or fixes were implemented
- Which files naturally group together
- Whether this should be one commit or multiple logical commits
- What architectural or product decisions were made

### 2. Plan Your Commits

Based on the changes and conversation history, plan your commit(s) following these principles:

**Commit Structure:**
- **Summary:** Action verb (Add/Update/Remove) + product-focused description
- **Body**
  - Why: Explain the motivation behind the change, including any architectural or product decisions made
  - How it fits: Describe how the change fits into the overall architecture or product vision
- **NO AI attribution:** Never include "Generated with Claude" or co-author lines
- **No Groupings:** There is no need to mention what ticket/bead this commit is related to

### 3. Present Your Plan

Show the user:
1. The number of commits you plan to create
2. For each commit:
   - The proposed commit message (summary + body if needed)
   - The files to be included
   - Brief explanation of the grouping rationale

Format:
```
I plan to create this commit:

[Summary line]
[Why]
[How it fits]

Does this commit plan look good?
```

### 4. Execute Upon Confirmation

Once the user confirms, create the commits:

1. Stage files explicitly (never use `git add -A` or `git add .`):
   ```bash
   git add file1.rb file2.rb spec/file1_spec.rb
   ```

2. Create commit with the planned message:
   ```bash
   git commit -m "Summary line

   - First bullet point
   - Second bullet point"
   ```

3. Show results:
   ```bash
   git log --oneline -n [number_of_commits]
   ```

## Important Rules

**NEVER include:**
- AI attribution or "Generated with Claude" messages
- Co-authored-by lines for AI tools
- References to AI assistance

**DO include:**
- Present tense verbs (Add, Update, Remove)
- Product-focused descriptions
- Architectural decisions and trade-offs (in body)
- Clear reasoning for changes

**Commit authorship:**
- Commits should be authored solely by the user
- You are helping draft messages, but they represent the user's decisions
- The user is responsible for understanding and maintaining this code

---

Now begin by running the git commands to understand the current state of changes.
