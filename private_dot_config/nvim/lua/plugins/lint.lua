return {
  {
    "mfussenegger/nvim-lint",
    opts = function(_, opts)
      local config_path = vim.fn.expand("~/.config/markdownlint-cli2.yaml")
      local args = { "--" }
      if vim.fn.filereadable(config_path) == 1 then
        args = { "--config", config_path, "--" }
      end

      opts.linters = opts.linters or {}
      opts.linters["markdownlint-cli2"] = {
        args = args,
      }

      return opts
    end,
  },
}
