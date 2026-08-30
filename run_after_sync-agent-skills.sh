#!/usr/bin/env bash
set -euo pipefail

# install-core runs before this script and provisions Node through mise. Chezmoi
# scripts do not share PATH changes, so include the user-local tool locations.
export PATH="$HOME/.local/bin:$HOME/.local/share/mise/shims:$PATH"

if command -v npx >/dev/null 2>&1; then
  npx_command=(npx)
elif command -v mise >/dev/null 2>&1; then
  npx_command=(mise exec node -- npx)
elif [ -x "$HOME/.local/bin/mise" ]; then
  npx_command=("$HOME/.local/bin/mise" exec node -- npx)
else
  echo "Cannot install agent skills: npx and mise are unavailable." >&2
  exit 1
fi

# Selecting both universal and Claude Code keeps the CLI in symlink mode: it
# stores canonical global copies in ~/.agents/skills and creates per-skill
# links in ~/.claude/skills. Re-adding everything refreshes existing skills and
# installs new ones without prompts.
echo "Syncing global agent skills from scottwater/skills..."
"${npx_command[@]}" --yes skills@latest add scottwater/skills \
  --global \
  --skill '*' \
  --agent universal claude-code \
  --yes
