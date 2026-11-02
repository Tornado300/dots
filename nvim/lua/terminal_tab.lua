-- Terminal, in its own dedicated tab: a bottom split is too small for
-- TUI-heavy tools (e.g. live object inspectors), and this way it doesn't
-- compete with code for screen space at all. toggle() jumps between
-- wherever you were and that tab, no matter how many other tabs are open --
-- it's not a plain tab-index toggle. position = 'current' fills the tab's
-- one window directly (a split/float would be redundant once it's the only
-- window). Backed by snacks.nvim's terminal (see plugins/snacks.lua).
local M = {}

local terminal_win = nil
local terminal_tab = nil
local last_code_tab = nil

--- Switch to the terminal tab (creating both tab and terminal if needed),
--- and return the underlying snacks.win so callers (e.g. the file-runner in
--- keybinds.lua) can send commands into its shell.
---@return snacks.win
function M.ensure()
  if terminal_tab and vim.api.nvim_tabpage_is_valid(terminal_tab) then
    vim.api.nvim_set_current_tabpage(terminal_tab)
  else
    vim.cmd 'tabnew'
    terminal_tab = vim.api.nvim_get_current_tabpage()
  end
  if not (terminal_win and terminal_win:buf_valid()) then
    -- start_insert/auto_insert off: by default snacks drops you into
    -- terminal-mode on open AND re-enters it every time you switch back into
    -- this buffer (its own permanent BufEnter autocmd) -- which breaks the
    -- <Tab>/<S-Tab> tab-switching keybinds, since those are normal-mode-only.
    -- Enter insert mode yourself (i/a) when you actually want to type into
    -- the shell.
    terminal_win = Snacks.terminal.open(nil, {
      win = { position = 'current' },
      start_insert = false,
      auto_insert = false,
    })
  end
  return terminal_win
end

--- Jump to the terminal tab, or back to whichever tab you were on before,
--- if you're already there.
function M.toggle()
  local current_tab = vim.api.nvim_get_current_tabpage()
  if terminal_tab and current_tab == terminal_tab then
    if last_code_tab and vim.api.nvim_tabpage_is_valid(last_code_tab) then
      vim.api.nvim_set_current_tabpage(last_code_tab)
    end
    return
  end
  last_code_tab = current_tab
  M.ensure()
end

return M
