return {
  {
    "adalessa/laravel.nvim",
    dependencies = {
      "MunifTanjim/nui.nvim",
      "nvim-lua/plenary.nvim",
      "nvim-neotest/nvim-nio",
      "folke/snacks.nvim",
    },
    ft = { "php", "blade" },
    event = { "BufEnter composer.json" },
    -- Avoid <leader>l (vim-test/LazyVim), <leader>L, gf, and <C-g>.
    keys = {
      {
        "<leader>cLl",
        function()
          Laravel.pickers.laravel()
        end,
        desc = "Laravel Picker",
      },
      {
        "<leader>cLa",
        function()
          Laravel.pickers.artisan()
        end,
        desc = "Laravel Artisan",
      },
      {
        "<leader>cLr",
        function()
          Laravel.pickers.routes()
        end,
        desc = "Laravel Routes",
      },
      {
        "<leader>cLm",
        function()
          Laravel.pickers.make()
        end,
        desc = "Laravel Make",
      },
      {
        "<leader>cLo",
        function()
          Laravel.pickers.resources()
        end,
        desc = "Laravel Resources",
      },
      {
        "<leader>cLc",
        function()
          Laravel.commands.run("actions")
        end,
        desc = "Laravel Actions",
      },
      {
        "<leader>cLv",
        function()
          Laravel.commands.run("view:finder")
        end,
        desc = "Laravel View Finder",
      },
      {
        "<leader>cLt",
        function()
          Laravel.commands.run("tinker:open")
        end,
        desc = "Laravel Tinker",
      },
    },
    opts = {
      features = { pickers = { provider = "snacks" } },
      extensions = {
        -- laravel_ls owns Laravel completion and view diagnostics; Blink uses LSP.
        completion = { enable = false },
        diagnostic = { enable = false },
      },
    },
  },
  {
    "folke/which-key.nvim",
    opts = { spec = { { "<leader>cL", group = "Laravel" } } },
  },
}
