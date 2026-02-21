# Forget Git Worktrees: Use Copy-on-Write Clones for Parallel AI Agents

I've been running multiple AI coding agents (Claude Code, Codex, Amp) in parallel on the same repo. The standard advice is to use `git worktree`. I tried it. It was fine until it wasn't. Here's what I do instead.

## The Problem

AI coding agents need their own working directory. You can't point three agents at the same checkout -- they'll stomp on each other's branches, dirty each other's working trees, and generally make a mess.

The typical solution is `git worktree`:

```bash
git worktree add ../agent-1 -b feature-a
git worktree add ../agent-2 -b feature-b
git worktree add ../agent-3 -b feature-c
```

This works. But worktrees share a single `.git` object store, which creates a few annoyances:

- Two worktrees can't have the same branch checked out
- Some tools don't handle worktrees well (looking at you, various editor plugins)
- You need to remember `git worktree remove` and `git worktree prune`
- Lock files and index state can get tangled in surprising ways
- The mental model is "one repo, multiple views" which is more complex than it sounds

I wanted something dumber.

## The Dumber Thing: `cp -cR`

On macOS with APFS, `cp -c` creates a **Copy-on-Write clone**. The copy is instant. It uses zero additional disk space. The OS shares the underlying data blocks and only allocates new storage when a file actually changes.

This means you can clone an entire git repo in milliseconds, for free:

```bash
cp -cR ./main ./larry
```

That's it. `larry` is now a fully independent git repo. Its own `.git`, its own index, its own branches. No shared state. No worktree bookkeeping. Just a directory.

## The Setup

The pattern is simple. You have a parent directory for each project, and inside it, a canonical clone named `main`:

```
~/projects/my-app/
  main/          # the canonical clone, kept read-only
  larry/         # agent workspace (CoW clone)
  curly/         # agent workspace (CoW clone)
  moe/           # agent workspace (CoW clone)
```

### Step 1: Create the canonical clone

```bash
mkdir -p ~/projects/my-app
cd ~/projects/my-app
git clone git@github.com:you/my-app.git main
```

### Step 2: Lock it

The `main` directory is your source of truth. You never work in it directly. Lock it read-only so you don't accidentally edit it:

```bash
cd main
find . -type d -exec chmod a-w {} +
find . -type f -exec chmod a-w {} +
```

### Step 3: Stamp out agent workspaces

```bash
cd ~/projects/my-app
cp -cR ./main ./larry
cp -cR ./main ./curly
cp -cR ./main ./moe
chmod -R u+w ./larry ./curly ./moe
```

Each copy is instant. Each is a full, independent repo. Point your agents at them and go.

## Working With It

### Giving an agent its workspace

```bash
# Claude Code
claude --project-dir ./larry

# Or just cd into it
cd ./larry
```

Each agent creates branches, makes commits, and pushes PRs from its own copy. They can't interfere with each other because there's nothing shared.

### Refreshing after a merge

Once a PR lands, you want the agents to start from the latest `main`. Update the canonical clone and re-stamp:

```bash
# Update the source of truth
cd ~/projects/my-app/main

# Temporarily unlock
find . -type d -exec chmod u+w {} +
find . -type f -exec chmod u+w {} +

# Pull latest
git fetch origin --prune
git pull --ff-only

# Re-lock
find . -type d -exec chmod a-w {} +
find . -type f -exec chmod a-w {} +
```

Then trash the old workspaces and create fresh ones:

```bash
cd ~/projects/my-app
rm -rf larry curly moe
cp -cR ./main ./larry
cp -cR ./main ./curly
cp -cR ./main ./moe
chmod -R u+w ./larry ./curly ./moe
```

### Cleaning up

```bash
rm -rf larry
```

That's the whole cleanup story. No `git worktree remove`. No `git worktree prune`. Just delete the directory.

## Wrapping It in Scripts

I got tired of typing the same commands, so I wrapped the pattern in a few small scripts that live in `~/.local/bin/`.

**`make-agent`** -- create a single agent workspace:

```bash
#!/usr/bin/env bash
set -euo pipefail

agent="$1"
src_name="${2:-main}"
src_dir="./${src_name}"
dst_dir="./${agent}"

if [[ -d "./.git" ]]; then
  echo "Run this from the parent directory, not inside a repo."
  exit 1
fi

if [[ ! -d "$src_dir/.git" ]]; then
  echo "Expected '$src_dir' to be a git repo."
  exit 1
fi

echo "Cloning $src_name -> $agent"
cp -cR "$src_dir" "$dst_dir"
chmod -R u+w "$dst_dir"
echo "Ready: $dst_dir"
```

**`make-agents`** -- stamp out all three at once:

```bash
#!/usr/bin/env bash
set -euo pipefail

src_name="${1:-main}"
src_dir="./${src_name}"
agents=(larry curly moe)

for a in "${agents[@]}"; do
  echo "Cloning $src_name -> $a"
  cp -cR "$src_dir" "./$a"
  chmod -R u+w "./$a"
  echo "$a ready"
done

echo "Done. Point your agents at ./larry, ./curly, ./moe"
```

**`update-main`** -- pull latest and re-lock:

```bash
#!/usr/bin/env bash
set -euo pipefail

cd ./main

# Unlock
find . -type d -exec chmod u+w {} +
find . -type f -exec chmod u+w {} +

# Update
git fetch origin --prune
git pull --ff-only

# Re-lock
find . -type d -exec chmod a-w {} +
find . -type f -exec chmod a-w {} +

echo "Updated and locked."
```

## Why Not Worktrees?

I'm not saying worktrees are bad. They're a fine feature. But for the specific use case of "I need three independent sandboxes for AI agents, right now," this pattern is simpler:

| | `git worktree` | `cp -cR` (CoW) |
|---|---|---|
| **Setup** | `git worktree add` | `cp -cR` |
| **Cleanup** | `git worktree remove` + `prune` | `rm -rf` |
| **Independence** | Shared `.git` object store | Fully independent |
| **Branch conflicts** | Can't checkout same branch twice | No restrictions |
| **Disk cost (macOS/APFS)** | Shared objects | Zero until divergence |
| **Tool compatibility** | Some tools struggle | Everything just works |
| **Mental model** | One repo, multiple views | Multiple repos, simple copies |

The CoW clone approach trades a tiny bit of purity for a lot of simplicity. Every copy is a real repo. Every tool works. There's nothing to manage.

## The Catch

This relies on APFS Copy-on-Write, which means macOS 10.13+ with an APFS-formatted volume (the default for years now). On Linux, you can get similar behavior with `cp --reflink=auto` on Btrfs or XFS. On ext4 or over NFS, `cp -cR` will fall back to a full copy -- still works, just slower and uses real disk space.

For most Mac-based development, this is a non-issue. Your disk is already APFS.

## The Full Workflow

1. Clone your repo into a `main/` directory
2. Lock `main/` read-only
3. `cp -cR` to create agent workspaces (larry, curly, moe -- or whatever names you like)
4. Point each AI agent at its own directory
5. Agents create branches, commit, push, open PRs
6. After merging, `update-main` and re-stamp fresh copies

No worktree commands to remember. No shared state to debug. Just directories.
