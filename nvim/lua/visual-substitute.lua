-- Visual-selection-scoped substitute: after visually selecting text and
-- pressing `:` (auto-fills `'<,'>`), typing `s` then `/` restricts the
-- substitution to the visually selected columns (via `\%V`) and switches
-- to very-magic regex (`\v`), instead of operating on the whole line.
--
-- Also: any `:...s<delim>...<delim>...<delim>flags` command (visual-scoped
-- or not) gets a `g` flag appended automatically on <CR> if it's missing,
-- so substitutions are global-per-line by default instead of first-match-only.
local want_v = false

-- only sets a flag, never overrides ':' itself
vim.keymap.set('x', ':', function()
  local mode = vim.fn.mode()
  want_v = (mode == 'v' or mode == 'V' or mode == '\22')
  return ':'
end, { expr = true, desc = "Command-line for selection (prefills '<,'>)" })

-- intercepts the '/' key, only right after typing 's' with a pending range
vim.keymap.set('c', '/', function()
  if want_v and vim.fn.getcmdline():match "^'<,'>s$" then
    want_v = false
    return [[/\%V\v]]
  end
  return '/'
end, { expr = true })

-- positions of every unescaped occurrence of `ch` in `str`
local function delim_positions(str, ch)
  local pos = {}
  for i = 1, #str do
    if str:sub(i, i) == ch and str:sub(i - 1, i - 1) ~= '\\' then
      pos[#pos + 1] = i
    end
  end
  return pos
end

vim.api.nvim_create_autocmd('CmdlineLeave', {
  pattern = ':',
  callback = function()
    want_v = false
    if vim.v.event.abort then
      return
    end
    local line = vim.fn.getcmdline()
    local delim = line:match 's(%p)'
    if not delim then
      return
    end
    local pos = delim_positions(line, delim)
    if #pos == 2 then
      -- pattern/replacement typed, no closing delimiter (so no flags yet)
      vim.fn.setcmdline(line .. delim .. 'g')
    elseif #pos >= 3 then
      local flags = line:sub(pos[3] + 1)
      if not flags:find('g', 1, true) then
        vim.fn.setcmdline(line .. 'g')
      end
    end
  end,
})
