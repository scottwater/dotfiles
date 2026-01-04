---
description: Run linting checks, then auto-commit valid changes
allowed-tools: ["Bash", "Read", "Grep", "Glob"]
---

# Quick Commit (QC)

Run all available linting checks first. If they pass, automatically commit changes without confirmation.

## Context Awareness

Before proceeding:
1. Review the conversation history to understand what was accomplished during this session
2. Check the current branch name for context
3. Use this context to write commits that accurately reflect the work's purpose

## Process

### 1. Detect and Run Linting Checks

First, detect which linting tools are available and run them ALL before proceeding.

**JavaScript/TypeScript checks** (if `package.json` exists):
- `npm run format` - Prettier formatting
- `npm run lint` - ESLint
- `npm run check` - TypeScript type checking
- `npm audit` - Security vulnerabilities in npm packages

**Ruby checks** (if `Gemfile` exists):
- `bin/rubocop` - Ruby style and linting
- `bin/brakeman --no-pager` - Security vulnerability scanning
- `bin/bundler-audit` - Known gem security vulnerabilities

**Run all available linters.** If ANY check fails:
- Report the specific failures clearly
- STOP - do not proceed to committing
- Suggest fixes if the issue is obvious

If ALL linting checks pass, proceed to step 2.

### 2. Analyze Changes

Run these commands to gather information:
- `git status` - See all modified, untracked, and staged files
- `git diff` - View unstaged changes in detail
- `git diff --staged` - View already-staged changes
- `git log --oneline -n 5` - Review recent commit style for consistency

### 3. Filter Files

**IGNORE these files (do not stage or commit):**
- All markdown files (`*.md`)
- Documentation files (`*.txt`, `*.rst`)
- Lock files that weren't intentionally changed
- Config files unrelated to the work (`.env`, credentials)
- Generated files (coverage reports, build artifacts)

**Report ignored files** at the start of output:
```
Ignored files (not part of this commit):
- README.md (markdown file)
- docs/setup.txt (documentation)
- CHANGELOG.md (markdown file)
```

If no files remain after filtering, report this and exit.

### 4. Plan Commits (Internal Only)

Analyze remaining changes to determine commit grouping:

**Commit Structure:**
- **Summary:** Action verb (Add/Update/Remove/Fix) + product-focused description
- **Body (optional):** Bulleted list of architectural decisions or trade-offs
- **NO AI attribution:** Never include "Generated with Claude" or co-author lines

**Grouping Strategy:**
- Schema/infrastructure changes first
- Core model or business logic second
- Controllers or services third
- UI components last
- Include related tests with the code they test

### 5. Execute Commits (No Confirmation Needed)

Stage files explicitly (never use `git add -A` or `git add .`):
```bash
git add file1.rb file2.rb spec/file1_spec.rb
```

Create commit with planned message:
```bash
git commit -m "Summary line

- First bullet point
- Second bullet point"
```

Repeat for each logical commit grouping.

### 6. Report Results

Show final status:
```bash
git log --oneline -n [number_of_commits_created]
```

Provide summary:
- Number of commits created
- Files committed per commit
- Files that were ignored (reminder)

## Important Rules

**NEVER include:**
- AI attribution or "Generated with Claude" messages
- Co-authored-by lines for AI tools
- Markdown files in commits (unless explicitly code-related like component.md templates)

**DO include:**
- Present tense verbs (Add, Update, Remove, Fix)
- Product-focused descriptions
- Architectural decisions in commit body when relevant

**Commit authorship:**
- Commits are authored solely by the user
- You are creating commits on their behalf based on the session's work

## Error Handling

**If linting fails:** Stop immediately, report failures, do not commit.

**If no committable files:** Report that all changed files were filtered out.

**If git operations fail:** Report the error and stop.

---

Now begin by detecting available linting tools and running all checks.
