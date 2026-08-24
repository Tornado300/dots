-- Visual-selection-scoped substitute: after visually selecting text and
-- pressing `:` (auto-fills `'<,'>`), typing `s` then `/` restricts the
-- substitution to the visually selected columns (via `\%V`) and switches
-- to very-magic regex (`\v`), instead of operating on the whole line.
local want_v = false

-- only sets a flag, never overrides ':' itself
vim.keymap.set('x', ':', function()
  want_v = (vim.fn.mode() == 'v')
  return ':'
end, { expr = true })

-- intercepts the '/' key, only right after typing 's' with a pending range
vim.keymap.set('c', '/', function()
  if want_v and vim.fn.getcmdline():match "^'<,'>s$" then
    want_v = false
    return [[/\%V\v]]
  end
  return '/'
end, { expr = true })

vim.api.nvim_create_autocmd('CmdlineLeave', {
  pattern = ':',
  callback = function()
    want_v = false
  end,
})
