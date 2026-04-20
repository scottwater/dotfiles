local function ruby_lsp_cmd()
  return { vim.fn.expand("~/.local/bin/nvim-ruby-lsp") }
end

return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        ruby_lsp = {
          mason = false,
          cmd = ruby_lsp_cmd(),
        },
        rubocop = { enabled = false, mason = false },
        standardrb = { enabled = false, mason = false },
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
