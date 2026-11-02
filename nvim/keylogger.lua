-- Temporary keystroke logger for usage analysis. Not part of the loaded
-- config — source it manually when you want to record a session:
--   :source ~/.config/nvim/keylogger.lua
-- Stop with :KeyLogStop. Log written to ~/nvim-keylog.txt, one line per
-- keypress: timestamp, ms-since-previous-keypress, mode, and the key in
-- keytrans() notation (so special keys show as <Space>, <C-w>, etc.
-- instead of raw bytes).
--
-- Terminals don't report "key held" as its own event — OS auto-repeat
-- just resends the same keypress at a fixed interval. The ms-delta column
-- is what lets you tell a held key (tight, near-constant deltas) apart
-- from you pressing the same key repeatedly by hand (looser, more
-- variable deltas) when you look at the log afterward.

local log_path = vim.fn.expand '~/nvim-keylog.txt'
local log_file = io.open(log_path, 'a')
local last_ns = nil

local ns = vim.on_key(function(_, typed)
  if not typed or typed == '' then
    return
  end
  local ok, notation = pcall(vim.fn.keytrans, typed)
  if not ok then
    return
  end
  local now = vim.loop.hrtime()
  local delta_ms = last_ns and math.floor((now - last_ns) / 1e6) or -1
  last_ns = now
  log_file:write(string.format('%s\t%d\t%s\t%s\n', os.date '%H:%M:%S', delta_ms, vim.api.nvim_get_mode().mode, notation))
  log_file:flush()
end)

vim.api.nvim_create_user_command('KeyLogStop', function()
  vim.on_key(nil, ns)
  log_file:close()
  print('Key logging stopped. Log at ' .. log_path)
end, {})

print('Key logging started -> ' .. log_path .. ' (stop with :KeyLogStop)')
