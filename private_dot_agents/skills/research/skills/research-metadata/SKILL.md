---
name: research-metadata
description: Extract metadata for thoughts documents (research, plans, tickets). Provides git context, timestamps, and branch-aware file discovery for consistent document frontmatter.
---

# Thoughts Metadata

This skill provides metadata extraction utilities for thoughts documents. It ensures consistent, accurate frontmatter across research documents, implementation plans, and other thoughts artifacts.

## Available Scripts

### Metadata Extraction (`spec_metadata.sh`)

Collects all necessary metadata before creating thoughts documents.

**Usage:**
```bash
./scripts/spec_metadata.sh
```

**Output includes:**
- Current date/time with timezone (ISO format)
- Git commit hash
- Current branch name
- Repository name
- Timestamp formatted for filenames

**Why this exists:** Research documents require consistent metadata in YAML frontmatter. Running this script before writing ensures all values are real and accurate, never placeholders.

## When to Use This Skill

Invoke this skill when you need to:
- Create a new research document and need metadata
- Create an implementation plan and need metadata
- Find existing research/plans for the current branch
- Ensure frontmatter consistency across documents

## Document Filename Conventions

All thoughts documents follow these naming patterns:

**With ticket:**
- `docs/research/YYYY-MM-DD-ENG-XXXX-description.md`

**Without ticket:**
- `docs/research/YYYY-MM-DD-description.md`

Where:
- `YYYY-MM-DD` is the creation date
- `ENG-XXXX` is the ticket number (omit if no ticket)
- `description` is a brief kebab-case description

## Frontmatter Template

Use this template for thoughts documents:

```yaml
---
date: [from spec_metadata.sh - Current Date/Time (TZ)]
git_commit: [from spec_metadata.sh - Current Git Commit Hash]
branch: [from spec_metadata.sh - Current Branch Name]
repository: [from spec_metadata.sh - Repository Name]
topic: "[Document Topic]"
ticket: [ENG-XXXX or omit if none]
tags: [relevant, component, names]
status: draft | in_progress | complete | approved
last_updated: [YYYY-MM-DD format]
---
```

## Validation Checklist

Before finalizing any thoughts document:
- [ ] Metadata gathered using spec_metadata.sh
- [ ] YAML frontmatter complete and correct
- [ ] Filename follows naming convention
- [ ] Branch context captured for future reference
