# Dotfiles

Personal dotfiles managed with [chezmoi](https://www.chezmoi.io/).

## Setup Instructions

```bash
chezmoi init scottwater/dotfiles
chezmoi apply
```

**Reminder for Scott**: Dracula Pro themes and TPM (tmux plugin manager) are pulled via `.chezmoiexternal.toml`

## Tools

### Shell & Terminal

- **zsh** - Shell with syntax highlighting and autosuggestions
- **[Starship](https://starship.rs/)** - Cross-shell prompt
- **[Atuin](https://atuin.sh/)** - Shell history sync and search
- **[Ghostty](https://ghostty.org/)** - Terminal emulator (Dracula Pro theme)
- **[tmux](https://github.com/tmux/tmux)** - Terminal multiplexer with Dracula Pro (Vampire Bat) theme

### Development Environment

- **[mise](https://mise.jdx.dev/)** - Runtime version manager (Ruby, Node, etc.)
- **[Neovim](https://neovim.io/)** - Editor (LazyVim configuration)
- **[Zed](https://zed.dev/)** - Code editor (Dracula Pro theme)

### Git & Version Control

- **[delta](https://github.com/dandavison/delta)** - Git diff viewer (Vampire Bat theme)
- **[bat](https://github.com/sharkdp/bat)** - Syntax-highlighted cat replacement (Vampire Bat theme)
- **[lazygit](https://github.com/jesseduffield/lazygit)** - Terminal UI for git

### AI Coding Assistants

- **[OpenCode](https://opencode.ai/)** - AI coding assistant with custom agents, commands, and themes
- **[Amp](https://ampcode.com/)** - AI coding assistant with custom commands and tools
- **[Claude Code](https://claude.ai/)** - AI coding assistant with custom skills

### Ruby/Rails Development

- **Bundler** - Ruby dependency management
- **RuboCop** - Ruby linter with custom git integration scripts
- **`t`** - Unified test runner for RSpec/Rails tests

## Managed Files & Directories

### Home Directory (`~`)

| Source | Destination | Description |
|--------|-------------|-------------|
| `dot_zshrc` | `~/.zshrc` | Zsh configuration with aliases and functions |
| `dot_zprofile` | `~/.zprofile` | Zsh profile (login shell) |
| `dot_gitconfig` | `~/.gitconfig` | Git configuration with aliases |
| `dot_gitignore_global` | `~/.gitignore_global` | Global git ignore patterns |
| `dot_gemrc` | `~/.gemrc` | Ruby gem configuration |
| `dot_tmux.conf` | `~/.tmux.conf` | Tmux configuration with Vampire Bat theme |
| `zsh/` | `~/zsh/` | Zsh plugins and helpers |

### Local Binaries (`~/.local/bin`)

| Source | Destination | Description |
|--------|-------------|-------------|
| `executable_t` | `~/.local/bin/t` | Unified test runner (RSpec/Rails) |
| `executable_spec_metadata` | `~/.local/bin/spec_metadata` | Spec metadata helper |
| `executable_rubocop-git` | `~/.local/bin/rubocop-git` | RuboCop git integration |

### Config Directory (`~/.config`)

| Source | Destination | Description |
|--------|-------------|-------------|
| `starship.toml` | `~/.config/starship.toml` | Starship prompt config |
| `ghostty/config` | `~/.config/ghostty/config` | Ghostty terminal config |
| `atuin/config.toml` | `~/.config/atuin/config.toml` | Atuin history config |
| `delta/themes.gitconfig` | `~/.config/delta/themes.gitconfig` | Delta themes |
| `lazygit/config.yml` | `~/.config/lazygit/config.yml` | Lazygit config |
| `nvim/` | `~/.config/nvim/` | Neovim/LazyVim configuration |
| `zed/` | `~/.config/zed/` | Zed editor settings and themes |
| `bat/` | `~/.config/bat/` | Bat config and Vampire Bat theme |
| `opencode/` | `~/.config/opencode/` | OpenCode AI assistant config |
| `amp/` | `~/.config/amp/` | Amp AI assistant config |
| `skills/` | `~/.config/skills/` | Shared AI skills (symlinked) |

### Claude Directory (`~/.claude`)

| Source | Destination | Description |
|--------|-------------|-------------|
| `settings.json` | `~/.claude/settings.json` | Claude Code settings |
| `ruby/auto_cop` | `~/.claude/ruby/auto_cop` | Auto-RuboCop hook |
| `skills` | `~/.claude/skills` | Symlink to shared skills |

## AI Skills

Custom skills shared across AI assistants:

- **gemini-imagegen** - Image generation via Gemini API (Nano Banana Pro)
- **dhh-rails-style** - 37signals/DHH Rails coding conventions
- **committing-with-guidelines** - Git commit message standards

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
