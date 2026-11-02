-- Cycle Neo-tree open/focus/close, bound to <M-h> in keybinds.lua: focus+
-- reveal if closed, switch focus to it if open but not focused, close it if
-- open and already focused.
local M = {}

function M.cycle()
  local manager = require 'neo-tree.sources.manager'
  local state = manager.get_state 'filesystem'
  if not (state and state.winid and vim.api.nvim_win_is_valid(state.winid)) then
    require('neo-tree.command').execute { action = 'focus', source = 'filesystem', reveal = true }
  elseif vim.api.nvim_get_current_win() ~= state.winid then
    vim.api.nvim_set_current_win(state.winid)
  else
    require('neo-tree.command').execute { action = 'close' }
  end
end

return M
