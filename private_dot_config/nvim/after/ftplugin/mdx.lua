vim.opt_local.wrap = true
vim.opt_local.linebreak = true
vim.opt_local.breakindent = true
vim.opt_local.textwidth = 80
vim.opt_local.formatoptions:append("t")

local function is_fence(line)
  return line:match("^%s*```") or line:match("^%s*~~~")
end

local function is_structure(line)
  return line:match("^%s*$")
    or line:match("^%s*#")
    or line:match("^%s*>")
    or line:match("^%s*[%-%*+]%s")
    or line:match("^%s*%d+[.)]%s")
    or line:match("^%s*|")
    or line:match("^%s*[-*_][-_*%s]*$")
end

local function line_at(bufnr, lnum)
  return vim.api.nvim_buf_get_lines(bufnr, lnum - 1, lnum, false)[1] or ""
end

local function format_range(start_line, end_line)
  vim.api.nvim_win_set_cursor(0, { start_line, 0 })
  if end_line > start_line then
    vim.cmd(("silent keepjumps normal! V%dGgq"):format(end_line))
  else
    vim.cmd("silent keepjumps normal! gqq")
  end
end

vim.api.nvim_buf_create_user_command(0, "MarkdownReflow", function()
  local view = vim.fn.winsaveview()
  local formatexpr = vim.bo.formatexpr
  local formatprg = vim.bo.formatprg
  vim.bo.formatexpr = ""
  vim.bo.formatprg = ""
  local ok, err = pcall(function()
    local bufnr = 0
    local lnum = 1
    local in_fence = false
    local line_count = vim.api.nvim_buf_line_count(bufnr)

    while lnum <= line_count do
      local line = line_at(bufnr, lnum)
      if is_fence(line) then
        in_fence = not in_fence
        lnum = lnum + 1
      elseif in_fence or is_structure(line) then
        lnum = lnum + 1
      else
        local start_line = lnum
        local scan = lnum + 1
        while scan <= line_count do
          local scan_line = line_at(bufnr, scan)
          if is_fence(scan_line) or is_structure(scan_line) then
            break
          end
          scan = scan + 1
        end
        local end_line = scan - 1
        format_range(start_line, end_line)
        line_count = vim.api.nvim_buf_line_count(bufnr)
        local next_line = start_line
        while next_line <= line_count do
          local current = line_at(bufnr, next_line)
          if is_fence(current) or is_structure(current) then
            break
          end
          next_line = next_line + 1
        end
        lnum = next_line
      end
    end
  end)
  vim.bo.formatexpr = formatexpr
  vim.bo.formatprg = formatprg
  vim.fn.winrestview(view)
  if not ok then
    vim.notify("MarkdownReflow failed: " .. tostring(err), vim.log.levels.ERROR)
  end
end, { desc = "Reflow markdown to 80 columns" })
