# 💤 LazyVim

A starter template for [LazyVim](https://github.com/LazyVim/LazyVim).
Refer to the [documentation](https://lazyvim.github.io/installation) to get started.

## PHP and Laravel

PHP support is imported in `lua/config/lazy.lua`, rather than relying on
`lazyvim.json`, which this repository excludes from Chezmoi syncing.
`lua/plugins/php.lua` adds:

- `laravel_ls` alongside Phpactor for Laravel-specific completion, navigation,
  and diagnostics in PHP/Blade. LazyVim installs it through Mason and passes
  its completions to Blink. It attaches to projects containing `artisan`.
- HTML language-server completion in HTML and Blade, with its formatter disabled.
- Blade, PHP, and embedded-PHP Tree-sitter parsers. Neovim detects `*.blade.php`
  as `blade`; no custom parser registration or filetype plugin is needed.
- `blade-formatter`, installed through Mason and run through Conform.
- Laravel Pint for PHP formatting when available (preferring `vendor/bin/pint`),
  falling back to PHP-CS-Fixer. They never run sequentially on the same file.
- PHPCS linting only when an ancestor directory contains `phpcs.xml`,
  `.phpcs.xml`, `phpcs.xml.dist`, or `.phpcs.xml.dist`, so its default style does
  not compete with Pint. Phpactor still provides PHP language diagnostics.

Your existing vim-test/Vimux setup supports PHPUnit and Pest; no second test
runner is installed. Run Neovim from the Laravel project root so project tools
and tests can find `artisan`, `composer.json`, and `vendor/`.

### Laravel commands

`lua/plugins/laravel.lua` configures [laravel.nvim](https://github.com/adalessa/laravel.nvim)
with the existing Snacks picker. Its completion and view-diagnostic extensions
are disabled in favor of `laravel_ls`; no Telescope, nvim-cmp, or neotest is added
(`nvim-nio` is an async dependency, not a test runner).

Press `<leader>cL` for the Laravel group:

- `l`: all commands; `a`: Artisan; `r`: routes; `m`: make; `o`: resources.
- `c`: Laravel actions; `v`: view finder; `t`: Tinker.

Existing test keys, `gf`, and `<C-g>` are unchanged. With a PHP/Blade file open,
run `:checkhealth laravel`. To select a project environment (local PHP, Herd,
Sail, etc.), run `:lua Laravel.commands.run("env:configure")`.
The plugin writes introspection/docblock helpers into `vendor/` and runs project
PHP, so only use these features in trusted projects with writable dependencies.

### Prerequisites and checks

1. Run `chezmoi apply` yourself, then restart Neovim and run `:Lazy sync`.
2. Make PHP 8.3+ (required by `laravel_ls`) and Composer available in the
   environment launching Neovim, and run `composer install` in the Laravel
   project. If the project does not include Pint, add it with
   `composer require laravel/pint --dev` if appropriate for the team. This
   configuration does not install a PHP runtime or change projects.
3. Run `:Mason` to check tool installation and `:TSUpdate` to update parsers.
   If macOS rejects a parser dylib, run the existing `:TSCodesignParsers` command.
4. Open a PHP file and check `:checkhealth vim.lsp` for Phpactor and `laravel_ls`.
   LazyVim's `<leader>cl` also opens the LSP configuration picker.
   In Blade, expect `html` and `laravel_ls`; also check `:set filetype?`
   (`blade`), `:InspectTree`, and `:ConformInfo` (`blade-formatter`).
   `<leader>cf` uses LazyVim's existing formatting action.

Selecting Sail/Herd in laravel.nvim configures that plugin's commands, not
Phpactor or Conform. `laravel_ls` documents Sail support separately. Container-only
PHP setups may need project-specific LSP, formatter, and test command wrappers.

### Optional project tools

- For Tailwind projects, enable `lang.tailwind` in `:LazyExtras`. That choice is
  machine-local unless added as an explicit import alongside the PHP extra.
- For deeper Eloquent type checking, consider project-local Larastan/PHPStan.
- Xdebug needs a separate DAP setup; this change does not install one.
- `laravel_ls` is still early-stage: its README lists Blade component-name/prop
  completion and Livewire support as unfinished. This setup is not full PhpStorm
  parity, nor a complete PHP type-checker inside Blade expressions.
