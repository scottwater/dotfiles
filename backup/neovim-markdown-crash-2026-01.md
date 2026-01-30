# Neovim markdown crash recovery notes (2026-01)

## Summary

Neovim (LazyVim) crashed on file open or when selecting files from the picker.
`nvim --clean` worked, so the issue was isolated to config/plugins. Crash reports
showed macOS code-signing invalid page faults while loading a mapped file, which
aligned with Tree-sitter parser shared libraries.

## Root cause

Corrupted or incompatible Tree-sitter parser shared libraries (.so), most likely
the markdown parsers. The crash manifested as a hard kill by macOS
code-signing (SIGKILL / Invalid Page) when a file was opened and Tree-sitter
attempted to load the parser.

## Resolution

1) Confirm config vs. core Neovim:
   - `nvim --clean` opened files without crashing.

2) Isolate Tree-sitter:
   - Disabling `nvim-treesitter` stopped the crash, confirming the parser path.

3) Re-enable Tree-sitter and rebuild parsers:
   - Re-enable `nvim-treesitter`.
   - Remove markdown parsers:
     - `trash ~/.local/share/nvim/site/parser/markdown.so`
     - `trash ~/.local/share/nvim/site/parser/markdown_inline.so`
   - Reinstall parsers:
     - `:TSInstall markdown`
     - `:TSInstall markdown_inline`
   - Open markdown to verify.

## Prevention

- If a crash recurs, remove only the markdown parsers and reinstall them.
- Avoid running `:TSUpdate` immediately after large OS/Homebrew upgrades.
  Run it once and verify markdown opens.
- Keep a note of crash logs in `~/Library/Logs/DiagnosticReports/` to confirm
  the invalid-page signature if it returns.

## Related files

- LazyVim config: `~/.config/nvim`
- Parsers directory: `~/.local/share/nvim/site/parser`
- Crash logs: `~/Library/Logs/DiagnosticReports/nvim-*.ips`
