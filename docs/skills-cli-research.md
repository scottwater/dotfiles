# `skills` CLI repository synchronization

Verified against the official [`vercel-labs/skills`](https://github.com/vercel-labs/skills)
source at commit [`435076e`](https://github.com/vercel-labs/skills/tree/435076e78988e1e6ec40d00b0b1d76bdbbc5419a).

## Recommended unattended install

```sh
npx --yes skills@latest add scottwater/skills \
  --global \
  --skill '*' \
  --agent universal claude-code \
  --yes
```

- `--global`, `--skill '*'`, agent selection, and `--yes` are documented add
  options. [`README.md`](https://github.com/vercel-labs/skills/blob/435076e78988e1e6ec40d00b0b1d76bdbbc5419a/README.md)
- Selecting both `universal` and `claude-code` is intentional. With multiple
  target directories, noninteractive add retains its default symlink mode. If
  only Claude Code is selected, the CLI treats it as a single target and uses
  copy mode. [`src/add.ts`](https://github.com/vercel-labs/skills/blob/435076e78988e1e6ec40d00b0b1d76bdbbc5419a/src/add.ts)
- In global symlink mode, canonical copies are placed under
  `~/.agents/skills`; Claude Code gets per-skill links under
  `~/.claude/skills` (or `$CLAUDE_CONFIG_DIR/skills`). Symlink failures fall
  back to copies. [`src/installer.ts`](https://github.com/vercel-labs/skills/blob/435076e78988e1e6ec40d00b0b1d76bdbbc5419a/src/installer.ts)
  and [`src/agents.ts`](https://github.com/vercel-labs/skills/blob/435076e78988e1e6ec40d00b0b1d76bdbbc5419a/src/agents.ts)
- Do not use add's `--all`: it means every skill **and every registered
  agent**, not every skill for selected agents.

Re-running add installs new skills and replaces existing skill directories, so
it also removes files deleted from a skill that still exists upstream.

## Upstream deletion limitation

The CLI cannot safely prune all skills from one repository in an unattended
Chezmoi hook:

1. `skills remove` accepts names, scope, agents, and `--all`, but has no
   repository/source filter. `--all --global` would remove unrelated global
   skills. [`src/remove.ts`](https://github.com/vercel-labs/skills/blob/435076e78988e1e6ec40d00b0b1d76bdbbc5419a/src/remove.ts)
2. `skills update -g` detects skills deleted upstream and can ask to remove
   them interactively. With `--yes` or non-TTY stdin, it explicitly skips the
   deletion. [`src/update.ts`](https://github.com/vercel-labs/skills/blob/435076e78988e1e6ec40d00b0b1d76bdbbc5419a/src/update.ts)
3. `skills ls -g --json` exposes provenance, so a custom filter/remove loop
   could be written, but the CLI does not provide that operation itself.
   [`src/list.ts`](https://github.com/vercel-labs/skills/blob/435076e78988e1e6ec40d00b0b1d76bdbbc5419a/src/list.ts)

Therefore the apply hook should only re-run add. A whole skill removed from the
repository will remain locally. To review and confirm detected deletions, run
`npx skills update -g` interactively.
