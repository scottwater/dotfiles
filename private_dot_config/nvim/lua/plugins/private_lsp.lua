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
        ruby_lsp = {},
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
