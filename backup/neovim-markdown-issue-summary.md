# Neovim markdown crash summary

## Steps taken

- Verified config scope by confirming `nvim --clean` could open files without crashing, isolating the issue to config/plugins.
- Checked LazyVim config and plugin list in `~/.config/nvim` and chezmoi-managed config for markdown-related settings.
- Identified Tree-sitter markdown parsers as a likely trigger, based on crashes during markdown open and macOS invalid page faults in crash logs.
- Disabled `nvim-treesitter` to confirm the crash stopped, then focused on parser rebuild.
- Inspected Neovim state/cache/logs (`~/.local/state/nvim`, `~/.cache/nvim`, `neo-tree.nvim.log`, `lsp.log`) to rule out unrelated errors.
- Confirmed render-markdown/markdown-preview plugins were present in the LazyVim ecosystem but not explicitly configured in user files.

## Results

- Root cause attributed to corrupted or incompatible Tree-sitter parser shared libraries (`markdown.so`, `markdown_inline.so`).
- Disabling Tree-sitter stopped the crash, confirming parser load as the trigger.
- Removing and reinstalling the markdown parsers restored normal markdown file opening.

## Recommendations for future incidents

- First check `nvim --clean` to isolate config/plugins vs. core Neovim.
- Temporarily disable `nvim-treesitter` if markdown files crash on open.
- Rebuild only markdown parsers:
  - `trash ~/.local/share/nvim/site/parser/markdown.so`
  - `trash ~/.local/share/nvim/site/parser/markdown_inline.so`
  - Reinstall via `:TSInstall markdown` and `:TSInstall markdown_inline`.
- Avoid running `:TSUpdate` immediately after major OS/Homebrew upgrades; update once, then verify markdown opens.
- If the crash repeats, capture the macOS diagnostic report from `~/Library/Logs/DiagnosticReports/nvim-*.ips` to confirm invalid-page faults.
