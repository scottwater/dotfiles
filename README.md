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

The managed theme is [Tokyo Night Dark](https://wixdaq.github.io/Tokyo-Night-Website/palette.html), the `night` variant with a `#1a1b26` background. TPM remains managed through `.chezmoiexternal.toml`; the private Dracula Pro external is disabled.

Theme coverage: Ghostty, tmux, Neovim, Zed, bat, delta, LazyGit, Hunk, Yazi, pgcli, Herdr, Pi, and zsh completion UI.

### Re-enabling Dracula Pro

The old private theme remains available as a dormant fallback:

1. Uncomment the `.config/nvim/dracula_pro` block in `.chezmoiexternal.toml`.
2. Run `DRACULA_PRO_THEMES_ENABLED=1 chezmoi apply` to pull the repo and enable the optional Zed copy hook.
3. Point the desired app configs back to the Dracula Pro theme names.

The existing `bat/themes/alucard.tmTheme` and Pi `themes/alucard.json` files are intentionally retained for that fallback.

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

- **[mise](https://mise.jdx.dev/)** - Runtime manager with pinned Ruby 4.0.6 and Node.js 24.19 defaults
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
