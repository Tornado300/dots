-- Animated half/full-page scroll, used by the <C-d>/<C-u>/<C-f>/<C-b> keybinds
-- in keybinds.lua. Wraps snacks.nvim's scroll animation module (opt-in only,
-- see plugins/snacks.lua): setting vim.b.snacks_scroll before issuing the
-- normal-mode scroll command makes it animate on the WinScrolled it triggers.
-- The flag is reset on a delay rather than immediately after, since
-- WinScrolled fires after this function returns, not synchronously within
-- it; the delay must outlast the animation (120ms/30ms in plugins/snacks.lua)
-- or a mid-animation reset aborts it.
local M = {}

---@param keys string native scroll keys to feed, e.g. '<C-d>'
---@return function
function M.scroll(keys)
  local termcodes = vim.api.nvim_replace_termcodes(keys, true, false, true)
  return function()
    local count = vim.v.count > 0 and tostring(vim.v.count) or ''
    vim.b.snacks_scroll = true
    vim.cmd('normal! ' .. count .. termcodes)
    vim.defer_fn(function()
      vim.b.snacks_scroll = false
    end, 250)
  end
end

return M
