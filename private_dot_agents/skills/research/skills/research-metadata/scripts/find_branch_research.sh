#!/usr/bin/env bash
set -euo pipefail

# Find thoughts documents relevant to the current branch
# This helps research and planning commands discover existing context

THOUGHTS_DIR="thoughts"

# Get current branch
if ! command -v git >/dev/null 2>&1 || ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "Error: Not in a git repository" >&2
  exit 1
fi

CURRENT_BRANCH=$(git branch --show-current 2>/dev/null || git rev-parse --abbrev-ref HEAD)
echo "Current Branch: $CURRENT_BRANCH"
echo ""

# Check if thoughts directory exists
if [ ! -d "$THOUGHTS_DIR" ]; then
  echo "No thoughts directory found. No existing research to discover."
  exit 0
fi

# Find main/master branch for comparison
MAIN_BRANCH=""
for branch in main master; do
  if git show-ref --verify --quiet "refs/heads/$branch" 2>/dev/null; then
    MAIN_BRANCH="$branch"
    break
  fi
done

echo "=== Documents Created on This Branch ==="
if [ -n "$MAIN_BRANCH" ] && [ "$CURRENT_BRANCH" != "$MAIN_BRANCH" ]; then
  # Find merge base (where this branch diverged)
  MERGE_BASE=$(git merge-base "$MAIN_BRANCH" HEAD 2>/dev/null || echo "")

  if [ -n "$MERGE_BASE" ]; then
    # Files added since branch diverged from main
    ADDED_FILES=$(git diff --name-only --diff-filter=A "$MERGE_BASE" HEAD -- "$THOUGHTS_DIR" 2>/dev/null || true)
    if [ -n "$ADDED_FILES" ]; then
      echo "$ADDED_FILES"
    else
      echo "(none found)"
    fi
  else
    echo "(could not determine branch point)"
  fi
else
  echo "(on main branch - showing recent thoughts files)"
  # On main, show files modified in last 20 commits
  git log --oneline -20 --name-only --diff-filter=A -- "$THOUGHTS_DIR" 2>/dev/null | grep -E "^$THOUGHTS_DIR/" | sort -u || echo "(none found)"
fi

echo ""
echo "=== Documents Tagged with This Branch ==="
# Search for documents with matching branch in frontmatter
if command -v grep >/dev/null 2>&1; then
  TAGGED_FILES=$(grep -rl "branch: $CURRENT_BRANCH" "$THOUGHTS_DIR" 2>/dev/null || true)
  if [ -n "$TAGGED_FILES" ]; then
    echo "$TAGGED_FILES"
  else
    echo "(none found)"
  fi
else
  echo "(grep not available)"
fi

echo ""
echo "=== All Thoughts Documents (by type) ==="

for subdir in research plans tickets; do
  DIR_PATH="$THOUGHTS_DIR/$subdir"
  if [ -d "$DIR_PATH" ]; then
    COUNT=$(find "$DIR_PATH" -name "*.md" -type f 2>/dev/null | wc -l | tr -d ' ')
    echo "$subdir/: $COUNT document(s)"
    # Show most recent 5
    find "$DIR_PATH" -name "*.md" -type f -print0 2>/dev/null | xargs -0 ls -t 2>/dev/null | head -5 | sed 's/^/  /'
  fi
done

echo ""
echo "=== Quick Reference ==="
echo "To read a document: Read tool with full path"
echo "To find by topic: grep -r 'topic:' thoughts/"
echo "To find by ticket: grep -r 'ENG-' thoughts/"
