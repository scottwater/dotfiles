# Safety Net

Cross-platform command safety for AI coding assistants. Blocks destructive commands like `rm -rf`, dangerous git operations, and more.

**Supports:** Amp, Claude Code, OpenCode

## Installation

### Amp

```bash
amp permissions add Bash --action delegate --to amp-safety-net
```

### Claude Code

Add to `~/.claude/settings.json`:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "bun run ~/.config/safety-net/cli.ts"
          }
        ]
      }
    ]
  }
}
```

### OpenCode

The plugin is automatically loaded from `~/.config/opencode/plugins/safety-net.ts`.

## What It Blocks

### rm -rf

- `rm -rf /` or `~` (always blocked)
- `rm -rf` outside of current working directory
- `rm -rf .` (current directory itself)

### Dangerous Git Operations

- `git checkout -- <path>` (discards changes)
- `git restore` (discards changes)
- `git reset --hard` (destroys uncommitted changes)
- `git clean -f` (removes untracked files)
- `git push --force` (without `--force-with-lease`)
- `git branch -D` (force delete without merge check)
- `git stash drop/clear` (permanently deletes stashes)

### Other Dangerous Patterns

- `find -delete`
- `xargs rm -rf`
- `parallel rm -rf`
- `dd of=`
- `mkfs`
- `shred`
- Writing to `/dev/sd*` or `/dev/hd*`

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `SAFETY_NET_STRICT` | off | Fail-closed on unparseable commands |
| `SAFETY_NET_PARANOID` | off | Enable all paranoid checks |
| `SAFETY_NET_PARANOID_RM` | **on** | Block `rm -rf` even within cwd (use `trash`) |
| `SAFETY_NET_PARANOID_INTERPRETERS` | off | Block `python -c`, `node -e`, etc. |
| `SAFETY_NET_ALLOW_TMP_RM` | on | Allow `rm -rf` in temp directories |

## Files

```
~/.config/safety-net/
├── core.ts              # Shared analysis logic
├── cli.ts               # CLI for Amp/Claude Code (stdin → exit code)
├── opencode-plugin.ts   # OpenCode plugin wrapper
└── README.md

~/.config/amp/safety-net/
└── amp-safety-net       # Amp delegate (calls cli.ts)

~/.config/opencode/plugins/
└── safety-net.ts        # Re-exports opencode-plugin.ts
```


## Prior Art

Based on ideas and code from https://github.com/Dicklesworthstone/misc_coding_agent_tips_and_scripts/blob/main/DESTRUCTIVE_GIT_COMMAND_CLAUDE_HOOKS_SETUP.md
