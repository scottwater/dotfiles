return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        -- Complements Phpactor; nvim-lspconfig scopes it to roots with artisan.
        laravel_ls = {},
        html = {
          filetypes = { "html", "blade" },
          -- Conform owns formatting, including Blade directives.
          init_options = { provideFormatter = false },
        },
      },
    },
  },
  {
    "nvim-treesitter/nvim-treesitter",
    opts = { ensure_installed = { "blade", "php", "php_only" } },
  },
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        -- Prefer the project's vendor/bin/pint; never run both PHP formatters.
        php = { "pint", "php_cs_fixer", stop_after_first = true },
        blade = { "blade-formatter" },
      },
    },
  },
  {
    "mason-org/mason.nvim",
    opts = { ensure_installed = { "blade-formatter" } },
  },
  {
    "mfussenegger/nvim-lint",
    opts = {
      linters = {
        phpcs = {
          -- Don't impose PHPCS's default style on projects using Laravel Pint.
          condition = function(ctx)
            return vim.fs.root(ctx.dirname, { "phpcs.xml", ".phpcs.xml", "phpcs.xml.dist", ".phpcs.xml.dist" }) ~= nil
          end,
        },
      },
    },
  },
}
