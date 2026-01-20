return {
  {
    "mason-org/mason-lspconfig.nvim",
    opts = {
      ensure_installed = {
        "ruby_lsp",
      },
    },
  },
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        ruby_lsp = {
          mason = false,
          cmd = { vim.fn.expand("~/.local/share/mise/shims/ruby-lsp") },
          init_options = {
            formatter = "standard",
            linters = { "standard" },
          },
        },
      },
      setup = {
        ruby_lsp = function(_, opts)
          require("lspconfig").ruby_lsp.setup(opts)
          return true -- Prevent duplicate setup
        end,
      },
    },
  },
}
