return {
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        ruby = { "standardrb" },
      },
      formatters = {
        standardrb = {
          command = vim.fn.expand("~/.local/share/mise/shims/standardrb"),
          args = { "--stderr", "--stdin", "$FILENAME", "--fix" },
          stdin = true,
        },
      },
    },
  },
  {
    "mason-org/mason.nvim",
    opts = {
      ensure_installed = {
        "standardrb",
      },
    },
  },
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        rubocop = { enabled = false },
      },
    },
  },
}
