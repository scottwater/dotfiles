local function codesign_treesitter_parsers(opts)
  opts = opts or {}

  if vim.fn.has("macunix") ~= 1 or vim.fn.executable("codesign") ~= 1 then
    return
  end

  local parser_dir = vim.fs.joinpath(vim.fn.stdpath("data"), "site", "parser")
  local parsers = vim.fn.glob(vim.fs.joinpath(parser_dir, "*.so"), false, true)
  if #parsers == 0 then
    return
  end

  local failures = {}
  for _, parser in ipairs(parsers) do
    local result = vim.system({ "codesign", "--force", "--sign", "-", parser }, { text = true }):wait()
    if result.code ~= 0 then
      table.insert(failures, vim.fn.fnamemodify(parser, ":t") .. ": " .. (result.stderr or result.stdout or "unknown error"))
    end
  end

  if #failures > 0 then
    vim.notify(
      "Failed to codesign tree-sitter parsers:\n" .. table.concat(failures, "\n"),
      vim.log.levels.ERROR,
      { title = "nvim-treesitter" }
    )
  elseif opts.notify then
    vim.notify(
      "Codesigned " .. #parsers .. " tree-sitter parser" .. (#parsers == 1 and "" or "s"),
      vim.log.levels.INFO,
      { title = "nvim-treesitter" }
    )
  end
end

return {
  {
    "nvim-treesitter/nvim-treesitter",
    init = function()
      local group = vim.api.nvim_create_augroup("treesitter_codesign_parsers", { clear = true })

      vim.api.nvim_create_autocmd("User", {
        group = group,
        pattern = "TSUpdate",
        callback = function()
          codesign_treesitter_parsers()
        end,
      })

      vim.api.nvim_create_user_command("TSCodesignParsers", function()
        codesign_treesitter_parsers({ notify = true })
      end, { desc = "Codesign nvim-treesitter parser dylibs on macOS" })
    end,
  },
}
