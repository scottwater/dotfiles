---
name: committing-with-guidelines
description: Write git commits that tell a story using clear structure and product-focused messaging. Use when creating commits to ensure they maintain historical context and aid code review.
---

# Git Commit Guidelines

## Purpose

Write git commits that tell a story, making it easier for code reviewers to understand changes and maintaining clear historical context for the codebase.

## Commit Message Structure

### Summary Line (Required)

Start with a concise action-oriented summary using one of these verbs:
- **Add** - New features, files, or functionality
- **Update** - Modifications to existing features or behavior
- **Remove** or **Delete** - Removing features, files, or functionality

**Format:** `[Action] [concise description of what changed from a product perspective]`

**Examples:**
- `Add team filtering to admin progress dashboard`
- `Update notification delivery to support multiple channels`
- `Remove deprecated API endpoints for user preferences`

### Body (Optional, but recommended for complex changes)

Use an unordered list to provide additional context when the summary alone isn't sufficient. Focus on:

- **Product/architecture decisions** - Why you made certain choices
- **System design implications** - How this affects the broader architecture
- **User-facing impact** - How this changes the product experience
- **Technical trade-offs** - Important decisions and their rationale

**Do NOT include:**
- A checklist of implementation tasks ("Added model X", "Created controller Y")
- Test additions or modifications (tests are expected as part of any commit)
- Low-level implementation details that are obvious from the code
- AI-generated code attribution or co-authorship

### When to Use the Body

Use a bulleted list when:
- The change affects multiple parts of the system
- There are important architectural or product decisions to explain
- The reasoning behind the change isn't obvious
- There are trade-offs that reviewers should understand

Skip the body when:
- The summary is completely self-explanatory
- The change is straightforward and localized
- The diff tells the complete story

## Commit Scope

Each commit should:
- Be atomic - represent one logical change
- Include all related changes (code + tests + docs)
- Pass tests and linting
- Tell one part of the overall story

When working on a feature, break it into logical commits that build on each other:

1. `Add database schema for team goals tracking`
2. `Add team goals model and associations`
3. `Add team goals admin interface`
4. `Add filtering and sorting to team goals dashboard`

## Planning Before Staging

Before staging any changes, take a moment to plan your commit strategy:

### Review Your Changes

```bash
git status           # See what files changed
git diff             # Review all unstaged changes
```

### Summarize Your Plan

Ask yourself:
- What story do these changes tell?
- Can I break this into logical commits that build on each other?
- What's the natural sequence someone would follow to understand this work?
- Are there unrelated changes that should be separate commits?

### Benefits of Planning

- **Cleaner history**: Each commit is atomic and tells one part of the story
- **Easier reviews**: Reviewers can understand changes incrementally
- **Better reverts**: If something breaks, you can revert a specific logical change
- **Forced reflection**: Planning makes you think about architecture and dependencies
- **Less rebasing**: Getting it right the first time means less cleanup later

### Use Partial Staging

Stage specific files or even specific lines:

```bash
git add -p                    # Interactively stage hunks
git add file1.rb file2.rb     # Stage specific files
```

## Reordering Commits for Better Storytelling

As you work, your commits might not end up in the most logical order. Use interactive rebase to rearrange them into a coherent narrative **before** opening a pull request.

### When to Rebase

Reorder commits when:
- Later work reveals a better logical sequence
- You've added related changes across multiple commits
- The commit history doesn't match how someone would understand the feature
- You need to fix or improve earlier commits
- The current order makes code review harder to follow

### Using Interactive Rebase

To reorder your last N commits:

```bash
git rebase -i HEAD~N
```

### Common Rebase Operations

In the interactive rebase editor:

- **`pick`** - Keep commit as-is
- **`reword`** - Keep changes but edit the commit message
- **`edit`** - Pause to amend the commit (add/remove changes)
- **`squash`** - Combine with previous commit, keep both messages
- **`fixup`** - Combine with previous commit, discard this message
- **`drop`** - Remove commit entirely

**To reorder:** Simply move the lines up or down to change commit order.

### Safety Guidelines

- **Never rebase commits that have been pushed to shared branches** (main, staging, etc.)
- Always rebase **before** pushing your branch for review
- If you've already pushed, use `git push --force-with-lease` carefully after rebasing
- Keep a backup branch before complex rebases: `git branch backup-branch-name`
- Test your code after rebasing to ensure nothing broke

## What NOT to Include

### AI-Generated Code Attribution

**Never include references to AI assistance or co-authorship in commit messages.**

❌ **Bad examples:**
```
Add user authentication
- Generated with AI assistance
```

```
Update notification system

Co-authored-by: Claude AI
Co-authored-by: GitHub Copilot
```

```
Add filtering feature (created with Cursor AI)
```

**Why:**
- Commits represent **your architectural decisions and ownership** of the code
- AI is a tool, like your IDE or linter - you don't credit those either
- Git history should focus on what changed and why, not how it was typed
- The developer is responsible for reviewing, testing, and maintaining the code
- Historical context should be about product/technical decisions, not implementation methods

**You are responsible for:**
- Understanding the code you commit
- Making architectural decisions
- Reviewing AI suggestions for correctness
- Testing and maintaining the code
- Explaining the reasoning behind changes

AI is a productivity tool. The commits should reflect your decisions and ownership.

## Additional Guidelines

- Use present tense ("Add feature" not "Added feature")
- Be specific but concise in the summary
- Avoid generic messages like "Fix bug" or "Update code"
- Reference ticket numbers in the branch name, not the commit message
- Keep the summary under 72 characters when possible
- Use the body to explain "why", not "what" (the diff shows "what")

## Review Before Committing

Ask yourself:
- If someone reads this commit in 6 months, will they understand **what** changed and **why**?
- Does this focus on the product/architecture outcome rather than implementation tasks?
- Am I telling a story or just documenting what I typed?
- Would a code reviewer understand the reasoning behind my decisions?

---

For detailed examples and scenarios, see EXAMPLES.md in this skill directory.
