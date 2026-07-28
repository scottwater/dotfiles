return {
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        eruby = { "htmlbeautifier" },
        ruby = { "standardrb" },
        markdown = { "prettier_prose" },
        ["markdown.mdx"] = { "prettier_prose" },
        yaml = { "yamlfix" },
        javascript = { "prettierd", "prettier" },
        typescript = { "prettierd", "prettier" },
        json = { "jq" },
      },
      formatters = {
        -- Prettier scoped to prose: reflows paragraphs to 80 cols on save
        -- while leaving fences, tables, and frontmatter structure intact.
        -- --no-config/--ignore-path keep project .prettierrc plugins and
        -- .prettierignore (e.g. blogee ignores src/**/*.md) from disabling it.
        prettier_prose = {
          command = "prettier",
          args = {
            "--stdin-filepath",
            "$FILENAME",
            "--no-config",
            "--ignore-path",
            "/dev/null",
            "--prose-wrap",
            "always",
            "--print-width",
            "80",
          },
          stdin = true,
        },
      },
    },
  },
  {
    "mason-org/mason.nvim",
    opts = { ensure_installed = { "prettier" } },
  },
}
