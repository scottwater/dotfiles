# Dotfiles

Personal dotfiles managed with [chezmoi](https://www.chezmoi.io/).

## Setup Instructions

The `lb` installer places Chezmoi in `~/.local/bin`, so none of these options
require a separate Chezmoi installation.

### Interactive bootstrap

The original command remains the default. On a fresh machine it asks for the
machine role and whether it is a Kode machine before applying the dotfiles.

```bash
sh -c "$(curl -fsLS get.chezmoi.io/lb)" -- init --apply git@github.com:scottwater/dotfiles.git
```

### Explicit workstation bootstrap

Use this when the machine should receive the complete workstation setup without
role prompts:

```bash
sh -c "$(curl -fsLS get.chezmoi.io/lb)" -- \
  init --apply \
  --promptChoice role=workstation \
  --promptBool kode=false \
  git@github.com:scottwater/dotfiles.git
```

Set `kode=true` for a Kode workstation.

### Explicit BB worker bootstrap

Use this while preparing the reusable worker image:

```bash
sh -c "$(curl -fsLS get.chezmoi.io/lb)" -- \
  init --apply \
  --promptChoice role=bb-worker \
  --promptBool kode=false \
  git@github.com:scottwater/dotfiles.git
```

The SSH repository URL requires GitHub access during the initial clone. An
interactive template build can use a forwarded SSH agent; copied workers retain
the initialized Chezmoi source and role configuration.

Next steps on macOS (local machine only):

```bash
chezmoi apply
brew bundle
```

Next steps on Linux (SSH-only):

```bash
chezmoi apply
```

## Machine roles

Initialization asks once for a machine role and stores it in the machine-local
Chezmoi config. `workstation` is the default and preserves the full desktop
setup. `bb-worker` installs the terminal development and agent environment but
omits workstation-only applications and services.

The bootstrap examples above can select either role without an interactive
prompt. The existing `kode` flag is independent of the machine role. Existing
installs without a stored role continue to render as `workstation`. Run
`chezmoi update --init` to persist the choice on one of those machines. Verify
a machine before sealing a worker image with:

```bash
chezmoi data --format=json | jq '{role, kode}'
```

The `bb-worker` role includes the full zsh environment, Neovim, LazyGit, Hunk,
Herdr, tmux, Yazi, Overmind, Pi, Codex, Claude Code, Pi packages, and shared
agent skills. Authentication remains a separate provisioning step.

After installing the coding harnesses, worker applies automatically run
`herdr integration install pi`, `herdr integration install claude`, and
`herdr integration install codex`. This installs Herdr's state-reporting hooks
and extension, preserves unrelated agent hooks/settings, and refreshes the
integrations on subsequent applies. It does not start agents, sign in, or enable
OpenCode/other integrations. Workstation integration choices are unchanged.
Restart already-running coding agents to load newly installed integrations;
`herdr integration status` reports their installed versions. See
[Herdr's integration documentation](https://herdr.dev/docs/integrations/).

Mise installs the 1Password CLI (`op`) for all roles on Linux and macOS through
`aqua:1password/cli`. Account sign-in remains manual; Chezmoi does not configure
authentication or enroll accounts. Workstations also pin Yarn Classic to
`1.22.22` via `npm:yarn`; Rails worker profiles install that same version with
their application Node, keeping it out of the lean base.

Workers have no global app Node, Ruby, or PHP runtime; profiles supply app
runtimes and their build dependencies. General build tools and SQLite remain.
Coding agents use mise-installed Node 24.19.0 through
`~/.local/share/orbi/tooling-node`, with Pi/Codex packages under
`~/.local/share/orbi/agents`. Their `~/.local/bin` wrappers always use that
runtime. Initial `node`, `npm`, and `npx` links point to tooling Node only when
absent; later Chezmoi runs preserve profile-selected app links. Worker agent
updates use the isolated prefix and runtime too. Workstation defaults are unchanged.

Worker bootstrap creates `~/code` without modifying existing projects. Interactive
zsh logins starting in the home directory enter `~/code`; noninteractive commands
and logins already in a project keep their working directory. Worker Herdr servers
use `terminal.new_cwd = "~/code"` for new panes, tabs, and workspaces, with explicit
`--cwd` taking precedence. This replaces Herdr's usual follow-current-pane default
on workers. Herdr-created worktrees live under `~/code/herdr-worktrees`.

BB source clones need an explicit worker `--target-path` under `/home/exedev/code`
(or register an existing checkout there). Shell defaults do not relocate BB's
managed worktrees or personal workspaces. No BB data directories are moved.

The managed theme is [Tokyo Night Dark](https://wixdaq.github.io/Tokyo-Night-Website/palette.html), the `night` variant with a `#1a1b26` background. TPM remains managed through `.chezmoiexternal.toml`; the private Dracula Pro external is disabled.

Theme coverage: Ghostty, tmux, Neovim, Zed, bat, delta, LazyGit, Hunk, Yazi, pgcli, Herdr, Pi, and zsh completion UI.

### Re-enabling Dracula Pro

The old private theme remains available as a dormant fallback:

1. Uncomment the `.config/nvim/dracula_pro` block in `.chezmoiexternal.toml`.
2. Run `DRACULA_PRO_THEMES_ENABLED=1 chezmoi apply` to pull the repo and enable the optional Zed copy hook.
3. Point the desired app configs back to the Dracula Pro theme names.

The existing `bat/themes/alucard.tmTheme` and Pi `themes/alucard.json` files are intentionally retained for that fallback.

## Worker updates

Role `bb-worker` installs `~/.local/bin/orbi-update`. Finish active work and push
your dotfile changes before running it on a VM:

```bash
orbi-update --dry-run
orbi-update
orbi-update --component agents --component herdr
orbi-update --yes
```

The default sequence is `chezmoi update`, `update-ai-tools` (Pi, Codex, Claude),
`mise upgrade herdr`, then a check that enrolled BB host services are active and
configured for automatic updates. BB follows the control server; this command
does not manually update or restart BB or Herdr. Chezmoi hooks may also update
tools, regardless of component selection.

The command checks the worker role, refuses dirty Chezmoi source changes, and
locks against concurrent updates. Failures stop later components without rolling
back earlier changes. Dry run prints the plan without running commands. Updates
to the updater itself take effect on the next invocation: Python loads the
current program before Chezmoi can replace its file.

Orbie's `provisioning/bin/update-worker` invokes this installed command remotely
for one VM or sequentially for `--all`. Workers need no control-server SSH key.
Refresh the template's Chezmoi configuration before building new worker images.

Run the updater and worker tooling tests from this source repository (template
checks require `chezmoi`; when `herdr` is available, its local integration
installers are tested in an isolated temporary home, never against live settings):

```bash
python3 -m unittest discover -s tests -q
```

## Installation Scripts

The install scripts run automatically via `chezmoi apply`:

- `run_after_install-core.sh.tmpl` - Cross-platform mise, runtime, Herdr, fnox, uv, and role-aware Atuin setup
- `run_after_install-linux.sh` - Ubuntu build dependencies and terminal utilities
- `run_onchange_after_install-pi.sh` - Installs Pi, Codex, Claude Code, and managed Pi packages
- `run_onchange_after_install-safety-guard.sh` - Installs and configures destructive_command_guard on macOS and Linux
- `run_after_set-pi-tokyonight-theme.sh` - Selects the managed Pi theme without replacing other Pi settings
- `run_after_install-dracula-pro-themes.sh` - Dormant Dracula Pro copy hook; requires `DRACULA_PRO_THEMES_ENABLED=1`

## Tools

### Shell & Terminal

- **zsh** - Shell with syntax highlighting and autosuggestions
- **[Pure](https://github.com/sindresorhus/pure)** - Zsh prompt
- **[Atuin](https://atuin.sh/)** - Shell history sync and search
- **[Ghostty](https://ghostty.org/)** - Terminal emulator (Tokyo Night Dark palette)
- **[tmux](https://github.com/tmux/tmux)** - Terminal multiplexer (Tokyo Night Dark status and pane styling)

### Development Environment

- **[mise](https://mise.jdx.dev/)** - Runtime manager with workstation defaults pinned to Ruby 4.0.6 and Node.js 24.19.0
- **[Neovim](https://neovim.io/)** - Editor (LazyVim configuration)
- **[Zed](https://zed.dev/)** - Code editor (Tokyo Night theme with Dark terminal overrides; install the `Tokyo Night` extension on a fresh machine)

### Git & Version Control

- **[delta](https://github.com/dandavison/delta)** - Git diff viewer (Tokyo Night Dark diff colors)
- **[bat](https://github.com/sharkdp/bat)** - Syntax-highlighted cat replacement (inherits Tokyo Night through ANSI colors)
- **[lazygit](https://github.com/jesseduffield/lazygit)** - Terminal UI for git (Tokyo Night Dark)
- **[hunk](https://github.com/modem-dev/hunk)** - Terminal UI for reviewing and staging git diffs (Tokyo Night Dark)
- **[Yazi](https://yazi-rs.github.io/)** - Terminal file manager (Tokyo Night Dark)

### AI Coding Assistants

- **[Pi](https://github.com/badlogic/pi-mono)** - Extensible coding harness with managed packages and settings
- **[Codex](https://github.com/openai/codex)** - OpenAI coding harness
- **[Claude Code](https://claude.ai/)** - Anthropic coding harness with shared skills
- **[destructive_command_guard](https://github.com/Dicklesworthstone/destructive_command_guard)** - Blocks destructive commands issued by coding agents

### Ruby/Rails Development

- **Bundler** - Ruby dependency management
- **RuboCop** - Ruby linter with custom git integration scripts
- **`t`** - Unified test runner for RSpec/Rails tests

## Managed Files & Directories

### Home Directory (`~`)

| Source | Destination | Description |
|--------|-------------|-------------|
| `dot_zshrc.tmpl` | `~/.zshrc` | Zsh configuration with aliases and functions |
| `dot_zprofile.tmpl` | `~/.zprofile` | Role-aware Zsh profile |
| `dot_gitconfig.tmpl` | `~/.gitconfig` | OS-aware Git configuration with aliases |
| `dot_gitignore_global` | `~/.gitignore_global` | Global git ignore patterns |
| `dot_gemrc` | `~/.gemrc` | Ruby gem configuration |
| `private_dot_config/tmux/` | `~/.config/tmux/` | Tmux configuration with Tokyo Night Dark theme |
| `zsh/` | `~/zsh/` | Zsh plugins and helpers |

### Local Binaries (`~/.local/bin`)

| Source | Destination | Description |
|--------|-------------|-------------|
| `executable_t` | `~/.local/bin/t` | Unified test runner (RSpec/Rails) |
| `executable_spec_metadata` | `~/.local/bin/spec_metadata` | Spec metadata helper |
| `executable_rubocop-git` | `~/.local/bin/rubocop-git` | RuboCop git integration |
| `executable_configure_age` | `~/.local/bin/configure_age` | Install age and copy `age.txt` from 1Password Dev vault |

### Config Directory (`~/.config`)

| Source | Destination | Description |
|--------|-------------|-------------|
| `ghostty/config` | `~/.config/ghostty/config` | Ghostty terminal config |
| `atuin/config.toml` | `~/.config/atuin/config.toml` | Atuin history config |
| `delta/themes.gitconfig` | `~/.config/delta/themes.gitconfig` | Delta themes |
| `lazygit/config.yml` | `~/.config/lazygit/config.yml` | Lazygit config |
| `nvim/` | `~/.config/nvim/` | Neovim/LazyVim configuration |
| `zed/` | `~/.config/zed/` | Zed editor settings and themes |
| `bat/` | `~/.config/bat/` | Bat config with terminal-palette syntax colors and optional legacy Alucard theme |
| `hunk/` | `~/.config/hunk/` | Hunk config with Tokyo Night Dark theme |
| `yazi/` | `~/.config/yazi/` | Yazi config with Tokyo Night Dark theme |
| `scottwater/skills` | `~/.agents/skills/` | Canonical global AI skills installed by the `skills` CLI |

### Claude Directory (`~/.claude`)

| Source | Destination | Description |
|--------|-------------|-------------|
| `settings.json` | `~/.claude/settings.json` | Claude Code settings |
| `ruby/auto_cop` | `~/.claude/ruby/auto_cop` | Auto-RuboCop hook |
| `scottwater/skills` | `~/.claude/skills` | Per-skill symlinks to `~/.agents/skills` |
| `symlink_CLAUDE.md` | `~/.claude/CLAUDE.md` | Symlink to `~/.config/AGENTS.md` |

### Shared AI Instructions

| Source | Destination | Description |
|--------|-------------|-------------|
| `private_dot_config/AGENTS.md` | `~/.config/AGENTS.md` | Shared agent instructions (Claude Code via symlink, other tools) |

## AI Skills

Every `chezmoi apply` installs all skills from
[`scottwater/skills`](https://github.com/scottwater/skills) globally through the
`skills` CLI. Canonical copies live in `~/.agents/skills`; Claude Code receives
per-skill symlinks in `~/.claude/skills`.

The apply hook adds new skills and refreshes existing ones. The CLI does not
currently offer non-interactive repository-scoped pruning, so a skill removed
upstream is not automatically deleted locally. Run `npx skills update -g`
interactively to review and confirm detected upstream deletions.

## Usage

```bash
# Apply dotfiles
chezmoi apply

# Edit a managed file
chezmoi edit ~/.zshrc

# Add a new file to management
chezmoi add ~/.config/some/file

# See what would change
chezmoi diff

# Pull and apply updates
chezmoi update
```
