# Never use rm

Never use `rm` or `rm -rf`. Instead use `trash` to delete files and directories.

# T3 Code Reviews

Use the t3-review skill

# MCP Servers

I use Hammer to manage most MCP connections.

You should have access to the following (and their may be more)

- PlanetScale
- Sentry
- HelpScout
- SideShow
- Jots
- Posthog
- Tovo

# Sandbox placeholders

Inside the Bash sandbox, untracked dotfiles at the repo root (.bashrc, .zshrc, .gitconfig, .mcp.json, .idea, .vscode, .claude/, etc.) are bubblewrap mount placeholders, not real files. Ignore them; never report, commit, or delete them.

