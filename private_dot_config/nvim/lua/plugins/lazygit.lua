return {
  "kdheepak/lazygit.nvim",
  cmd = {
    "LazyGit",
    "LazyGitConfig",
    "LazyGitCurrentFile",
    "LazyGitFilter",
    "LazyGitFilterCurrentFile",
  },
  dependencies = {
    "nvim-lua/plenary.nvim",
  },
  keys = {
    { "<leader>gg", "<cmd>LazyGit<cr>", desc = "LazyGit" },
  },
  config = function()
    -- Ensure terminal has proper color support for LazyGit theming
    vim.g.lazygit_floating_window_scaling_factor = 0.9

    -- Set up autocmd to configure terminal when LazyGit opens
    vim.api.nvim_create_autocmd("TermOpen", {
      pattern = "term://*lazygit",
      callback = function()
        -- Ensure the terminal buffer uses 24-bit color
        vim.opt_local.termguicolors = true
        -- Set COLORTERM for true color support
        vim.env.COLORTERM = "truecolor"
      end,
    })
  end,
}
