# Laravel editor support

The personal `~/.local/bin/laravel-ide-helper` command generates editor definitions
using each project's installed version of `barryvdh/laravel-ide-helper`:

```sh
laravel-ide-helper
laravel-ide-helper /path/to/project
```

Without an argument, it searches upward from the current directory for a Laravel
project. PHP comes from PATH, including Herd when configured in your shell.
Projects need their Composer development dependencies installed. For a new project
without IDE Helper, install it with `composer require --dev barryvdh/laravel-ide-helper`.
The launcher assumes Composer's standard `vendor` directory.

Run again after upgrading Laravel or changing facade registrations or macros.
The generated `_ide_helper.php` stays in the project for the editor to index,
including aliases such as `\DB` and `\Storage`. It is ignored through
`~/.gitignore_global`; do not sync it or add it to Composer autoloading.
Application files are not modified.

## Zed

Personal Zed settings select Intelephense and the official Laravel extension for
PHP and the official Laravel extension for Blade. Install those extensions on
each machine. The Intelephense file-size limit is 5 MB so it indexes the helper.
If diagnostics stay stale, run `editor: restart language server` in Zed's palette.
Project-specific settings can override these personal defaults.

`diagnostics.argumentCount: "declared"` retains argument-count checks for declared
functions and methods while skipping PHPDoc-only signatures. This avoids the
reproduced optional `find`/`where` P1005 errors and variadic `select` P1119 hints.
Other analysis or tests must catch argument-count errors on PHPDoc-only methods;
other Intelephense checks remain enabled.

The launcher, this note, Zed settings, and global Git ignore are managed by chezmoi.
On another machine, sync your dotfiles and run `chezmoi apply` yourself, install the
project's development dependencies, then run `laravel-ide-helper` locally.

## Lendr project analysis

Lendr separately keeps Larastan/PHPStan as project development dependencies and
`phpstan.neon` as project configuration. From the project root:

```sh
composer analyse
mkdir -p docs/reports
composer analyse:json > docs/reports/phpstan.json
```

Findings produce a nonzero exit status. Check the JSON report's top-level `errors`
as well as its per-file findings to distinguish an incomplete run from findings.
The current configuration checks app, bootstrap, config, database, and routes at
level 5 with PHP 8.3.6; excludes generated bootstrap cache; and has no baseline or
CI gate. Tests, Blade templates, frontend code, vendor, and helper files are not
analysis targets. Review findings by identifier before changing code.
These findings are separate from Zed's editor diagnostics.
