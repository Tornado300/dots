-- Run the current file in the persistent terminal tab (see terminal_tab.lua),
-- bound to <leader>xr in keybinds.lua.
--
-- To support a new filetype, just add an entry to M.commands below: a list
-- of shell command templates, run in order and stopping on the first
-- failure. {file} is replaced with the current file's shell-escaped name.
local terminal_tab = require 'terminal_tab'

local M = {}

M.commands = {
  javascript = { 'node {file}' },
  typescript = { 'npx tsx {file}' },
  sh = { 'bash {file}' },
  go = { 'go run {file}' },
  lua = { 'lua {file}' },
}

function M.run()
  local steps = M.commands[vim.bo.filetype]
  if not steps then
    vim.notify('No run command configured for filetype: ' .. vim.bo.filetype, vim.log.levels.WARN)
    return
  end

  -- escape '%' first: it's a gsub replacement-string escape char, and could
  -- otherwise appear literally in a shell-escaped filename.
  local file = vim.fn.shellescape(vim.fn.expand '%:t'):gsub('%%', '%%%%')
  local parts = {}
  for _, step in ipairs(steps) do
    table.insert(parts, (step:gsub('{file}', file)))
  end

  -- cd first: the terminal's shell is long-lived and reused across runs, so
  -- its cwd is wherever it started, not necessarily this file's directory.
  local dir = vim.fn.shellescape(vim.fn.expand '%:p:h')
  local cmd = 'cd ' .. dir .. ' && ' .. table.concat(parts, ' && ')

  local term = terminal_tab.ensure()
  vim.fn.chansend(vim.bo[term.buf].channel, cmd .. '\n')
end

--- @param filetype string
--- @param commands string|string[] one command, or several run in order
function M.config_ft(filetype, commands)
  M.commands[filetype] = type(commands) == 'string' and { commands } or commands
end

return M
