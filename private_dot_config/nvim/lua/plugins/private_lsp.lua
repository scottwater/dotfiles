local function ruby_lsp_cmd()
  local shims = vim.fn.expand("~/.local/share/mise/shims")
  local path = shims .. ":" .. (vim.env.PATH or "")

  return {
    "/usr/bin/env",
    "-u",
    "RUBYLIB",
    "-u",
    "RUBYOPT",
    "-u",
    "GEM_HOME",
    "-u",
    "GEM_PATH",
    "-u",
    "BUNDLE_GEMFILE",
    "-u",
    "BUNDLE_PATH",
    "-u",
    "BUNDLE_BIN",
    "-u",
    "BUNDLE_BIN_PATH",
    "-u",
    "BUNDLE_WITHOUT",
    "-u",
    "BUNDLE_FROZEN",
    "-u",
    "RUBYGEMS_GEMDEPS",
    "PATH=" .. path,
    shims .. "/ruby-lsp",
  }
end

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
