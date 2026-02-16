# Scripts

Utility scripts for the thoughts-metadata skill.

## spec_metadata.sh

Collects metadata for thoughts documents.

**Purpose**: Gathers all necessary metadata (date/time, git info) before creating thoughts documents to avoid placeholder values.

**Usage**:
```bash
./plugins/research/skills/thoughts-metadata/scripts/spec_metadata.sh
```

**Output includes**:
- Current date/time with timezone (ISO format)
- Git commit hash
- Current branch name
- Repository name
- Timestamp formatted for filenames

**Why this exists**: Thoughts documents require consistent metadata in YAML frontmatter. Running this script before writing ensures all values are real and accurate, never placeholders.

## find_branch_research.sh

Discovers thoughts documents relevant to the current branch.

**Purpose**: Helps research commands find existing context (research, plans, tickets) for the current feature branch.

**Usage**:
```bash
./plugins/research/skills/thoughts-metadata/scripts/find_branch_research.sh
```

**Output includes**:
- Documents created on this branch (since diverging from main)
- Documents with frontmatter `branch:` matching current branch
- Summary of all thoughts documents by type
- Quick reference commands for further exploration

**Why this exists**: When working on a feature, you need context from previous research. This script finds all relevant thoughts documents so you don't start from scratch.

## Guidelines

- Scripts should solve problems, not punt to Claude
- Include error handling
- Document why constants have specific values
- Use forward slashes for paths (cross-platform)
