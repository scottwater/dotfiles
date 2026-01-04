---
name: preparing-branch-for-pr
description: Prepare your branch for PR submission by analyzing commits, organizing the narrative, and creating a PR overview. Use when you're ready to finalize your branch and submit a pull request.
---

# Preparing Branch for PR

This skill analyzes your current branch, gathers related context, and helps you organize commits into a cohesive story that's ready for pull request submission.

## Initial Response

When invoked, respond with:

```
I'm ready to prepare your branch for PR submission. Please provide any additional context about this work, or press Enter if the commits and related files tell the full story.
```

If the user provided context via $ARGUMENTS, acknowledge it and skip asking for additional input.

Then proceed to gather information.

## Core Workflow

### 1. Gather Branch Information

Run these commands in parallel to understand the current state:

```bash
# Get current branch name
git branch --show-current

# Get base branch (usually main)
git symbolic-ref refs/remotes/origin/HEAD | sed 's@^refs/remotes/origin/@@'

# View all commits since diverging from base branch
git log --oneline main..HEAD

# View full commit messages and diffs since base branch
git log main..HEAD

# Check for pending changes
git status

# View pending unstaged changes
git diff

# View pending staged changes
git diff --staged
```

### 2. Search for Related Context Files

Search these directories for files related to the current branch name or ticket number:

**Check `thoughts/` directory:**
```bash
# Search for files matching branch name or ticket
if [ -d thoughts ]; then
  find thoughts -type f -name "*<branch-name>*" -o -name "*<ticket-number>*"
fi
```

**Check `workflow/` directory (research and plans):**
```bash
# Search workflow research and plans directories
if [ -d workflow/research ]; then
  find workflow/research -type f -name "*<branch-name>*" -o -name "*<ticket-number>*"
fi

if [ -d workflow/plans ]; then
  find workflow/plans -type f -name "*<branch-name>*" -o -name "*<ticket-number>*"
fi
```

Read any relevant files found to gather context about:
- Original goals and requirements
- Architectural decisions
- Implementation notes
- User stories or acceptance criteria

### 3. Create Research Plan

Use TodoWrite to create a plan for organizing the branch:

```
- Analyze commit history and narrative flow
- Review pending changes that need commits
- Check for commit reorganization opportunities
- Propose commit strategy
- Execute commit organization (if needed)
- Generate PR overview (if requested)
```

### 4. Analyze Commit History and Narrative

Based on all gathered information, analyze:

**Commit Story Arc:**
- Do commits build logically on each other?
- Is there a clear narrative from foundation → implementation → UI?
- Are commits atomic and focused?
- Do commit messages follow the story-driven guidelines?

**Commit Message Quality:**
- Do summaries use action verbs (Add/Update/Remove)?
- Are messages product-focused rather than task-focused?
- Do bodies explain "why" and architectural decisions?
- Are any commits too broad and should be split?
- Are any commits too granular and should be combined?

**Pending Changes:**
- Are there uncommitted changes that need new commits?
- Should these be integrated into existing commits (amend) or be new commits?
- What's the logical placement in the narrative?

**Related Context:**
- Does the work align with goals in `thoughts/` or `workflow/` directories?
- Are there architectural decisions from context that should be reflected in commit messages?
- Is the overall narrative clear when commits are read in sequence?

### 5. Present Commit Strategy

Show the user a comprehensive analysis:

```markdown
## Current Branch Analysis

**Branch**: [branch-name]
**Base**: [base-branch]
**Commits**: [N commits since diverging]
**Pending Changes**: [Yes/No - summary if yes]

### Related Context Found
- `thoughts/[file]` - [brief description]
- `workflow/research/[file]` - [brief description]
- `workflow/plans/[file]` - [brief description]

### Current Commit History
1. [commit-hash] [commit-message]
2. [commit-hash] [commit-message]
...

### Analysis

[Your analysis of the current narrative, identifying:]
- ✅ What's working well
- ⚠️ Opportunities for improvement
- 💡 Recommendations for reorganization (if any)

### Proposed Strategy

[Choose one of these approaches:]

**Option A: Commits are well-organized (no rebase needed)**
- Your commits already tell a cohesive story
- [If pending changes] Create [N] new commit(s) for pending changes:
  - Commit: [proposed summary]
    Files: [list]
    Rationale: [why]

**Option B: Recommend rebase for better narrative**
- Reorder commits to improve story flow
- Suggested new sequence:
  1. [commit] - [rationale for placement]
  2. [commit] - [rationale for placement]
  ...
- [If needed] Squash commits X and Y because [reason]
- [If needed] Split commit Z into [A] and [B] because [reason]

**Option C: Create commits for pending changes, then rebase**
- First, commit pending changes: [proposed commits]
- Then, rebase to organize the full story: [proposed sequence]

### Next Steps

Would you like me to:
1. Proceed with this strategy?
2. Adjust the approach?
3. Skip reorganization and move to PR overview?
```

### 6. Execute Upon Approval

Based on the user's decision:

**CRITICAL: Always Create Backup Branch First**

Before ANY major git operations (rebase, amend, etc.), ALWAYS create a backup branch:

```bash
# Get current branch name
CURRENT_BRANCH=$(git branch --show-current)

# Create backup with timestamp
BACKUP_NAME="${CURRENT_BRANCH}-backup-$(date +%Y%m%d-%H%M%S)"

# Create the backup
git branch $BACKUP_NAME

# Inform user
echo "✅ Created backup branch: $BACKUP_NAME"
echo "If anything goes wrong, restore with: git reset --hard $BACKUP_NAME"
```

Present to user:
```
I've created a backup branch '$BACKUP_NAME' before making changes. If anything goes wrong, you can restore your work with:
  git reset --hard $BACKUP_NAME
```

**If creating new commits only (no rebase/amend):**
- Backup branch is NOT needed for simple new commits
- Invoke the `committing-with-guidelines` skill
- Pass relevant context about the work
- Follow the standard commit workflow

**If rebasing:**
- **First**: Create backup branch (see above) - MANDATORY
- Check if commits have been pushed to shared branches:
  ```bash
  git log --oneline @{u}..HEAD
  ```
- If pushed, warn user about force-push implications
- Provide clear instructions for interactive rebase:
  ```bash
  git rebase -i HEAD~N
  ```
- Explain the rebase operations needed (reorder, squash, reword, etc.)
- Remind to test after rebasing
- Inform about backup restoration if needed

**If amending commits:**
- **First**: Create backup branch (see above) - MANDATORY
- Check commit hasn't been pushed or isn't authored by someone else
- Proceed with amend operation
- Remind about backup restoration if needed

**If both (new commits + rebase):**
- First create new commits using the skill (no backup needed yet)
- Then create backup branch before rebase (MANDATORY)
- Guide through rebase process

### 7. Offer PR Overview Generation

After commits are finalized, ask:

```
Your branch is now organized and ready for PR submission. Would you like me to generate a PR overview document that summarizes this work?
```

If yes, create a PR overview in `thoughts/prs/` directory:

**Filename format:**
- With ticket: `thoughts/prs/YYYY-MM-DD-ENG-XXXX-brief-description.md`
- Without ticket: `thoughts/prs/YYYY-MM-DD-brief-description.md`

**Structure:**

```markdown
---
date: [Current date and time with timezone]
branch: [branch-name]
base_branch: [base-branch]
ticket: [ticket-number if applicable]
author: [Git author from commits]
status: ready-for-review
commits: [number of commits]
---

# PR: [Brief title describing the work]

## Summary

[2-3 sentences describing what this PR accomplishes from a product perspective]

## Changes Overview

[High-level summary of the changes organized by area:]

### [Area 1] (e.g., Authentication, Database Schema, UI Components)
- [Key change 1]
- [Key change 2]

### [Area 2]
- [Key change 1]
- [Key change 2]

## Commit Story

This PR is organized into [N] commits that tell the following story:

1. **[Commit summary 1]**
   - [Why this commit is first / sets foundation]

2. **[Commit summary 2]**
   - [How this builds on the foundation]

[Continue for all commits...]

## Architectural Decisions

[Key architectural decisions made, trade-offs considered, and rationale - drawn from commit bodies, thoughts files, and context]

- **[Decision 1]**: [Rationale]
- **[Decision 2]**: [Rationale]

## Testing Approach

[How to test this PR - if tests are included, mention them; if manual testing needed, provide steps]

- [ ] [Test case 1]
- [ ] [Test case 2]
- [ ] [Test case 3]

## Related Context

- Ticket: [link or reference]
- Related thoughts: `thoughts/[file]`
- Related research: `workflow/research/[file]`
- Related plans: `workflow/plans/[file]`

## Reviewer Notes

[Any specific areas that need attention, known limitations, or follow-up work planned]
```

Present the PR overview to the user and save it to the file.

## Important Guidelines

**Branch Analysis:**
- Consider the full context: commits, pending changes, and related documentation
- Respect existing commit organization if it's already good
- Only suggest reorganization when it meaningfully improves the narrative
- Focus on making the story clear for reviewers

**Commit Organization:**
- Use the existing `committing-with-guidelines` skill for commit creation
- Follow the story-driven commit guidelines throughout
- Ensure commits are atomic and build logically
- Maintain focus on product/architecture decisions in commit messages

**PR Overview:**
- Make it self-contained so reviewers understand the context
- Highlight the narrative arc through commits
- Include architectural decisions and rationale
- Provide clear testing guidance
- Link to related context for deeper understanding

**Safety:**
- ALWAYS create backup branch before rebase, amend, or other destructive operations
- Never force dangerous git operations
- Warn about rebase risks if commits are already pushed
- Provide clear restoration instructions with backup branch name
- Test after any git history modifications

## Validation Checklist

Before finalizing:

- [ ] All context sources checked (thoughts, workflow/research, workflow/plans)
- [ ] Commit history analyzed for narrative flow
- [ ] Pending changes identified and planned
- [ ] Strategy presented clearly with rationale
- [ ] User approved the approach
- [ ] **Backup branch created before any rebase/amend operations**
- [ ] User informed of backup branch name and restoration command
- [ ] Commits organized (if needed)
- [ ] PR overview generated (if requested)
- [ ] All file references are correct
- [ ] Final branch tells a cohesive story

## Example Flow

```
User: /prepare-pr

Skill: I'm ready to prepare your branch for PR submission. Please provide any additional context about this work, or press Enter if the commits and related files tell the full story.

User: This adds the new preparing-branch-for-pr skill to the git-commit plugin

Skill: [Runs git commands to analyze branch]
Skill: [Searches thoughts, workflow/research, workflow/plans directories]
Skill: [Creates TodoWrite plan]
Skill: [Analyzes commits and presents strategy]

## Current Branch Analysis

**Branch**: add-prepare-pr-skill
**Base**: main
**Commits**: 3 commits since diverging
**Pending Changes**: Yes - 1 modified file, 1 new file

### Related Context Found
- No related files found in thoughts/, workflow/research/, or workflow/plans/

### Current Commit History
1. abc1234 Add prepare-pr command to git-commit plugin
2. def5678 Create preparing-branch-for-pr skill directory
3. ghi9012 Add preparing-branch-for-pr skill implementation

### Analysis

✅ What's working well:
- Commits follow logical progression (command → directory → skill)
- Using present tense action verbs
- Clear, descriptive messages

⚠️ Opportunities for improvement:
- Consider combining first two commits since directory creation is part of setup
- Pending changes should be committed

### Proposed Strategy

**Option A: Create commit for pending changes**
- Your commits already tell a cohesive story
- Create 1 new commit for pending changes:
  - Commit: "Update preparing-branch-for-pr skill documentation"
    Files: SKILL.md
    Rationale: Complete the skill documentation

### Next Steps

Would you like me to:
1. Proceed with this strategy?
2. Adjust the approach?
3. Skip reorganization and move to PR overview?

User: Proceed with the strategy

Skill: [Invokes committing-with-guidelines skill to create the new commit]
Skill: Commit created successfully. Your branch is now organized and ready for PR submission. Would you like me to generate a PR overview document that summarizes this work?

User: Yes

Skill: [Creates PR overview in thoughts/prs/2025-11-18-add-prepare-pr-skill.md]
Skill: I've created a PR overview at thoughts/prs/2025-11-18-add-prepare-pr-skill.md that summarizes your changes and provides context for reviewers.
```

## Key Principles

1. **Safety first**: ALWAYS create backup branches before destructive git operations
2. **Be thorough but respectful**: Analyze everything but respect good existing organization
3. **Context is king**: Use all available context to inform decisions
4. **Tell a story**: Every branch should have a clear narrative arc
5. **User empowerment**: Present options and explain tradeoffs clearly
6. **Quality focus**: Ensure commits follow story-driven guidelines
7. **Documentation**: Generate helpful PR overviews that make reviews easier

---

Remember: The goal is to help users submit branches that tell a clear, reviewable story and make the reviewer's job easier through well-organized commits and comprehensive PR documentation.