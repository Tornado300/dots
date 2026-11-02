function wrap(callable, args)
  local func
  if type(args) == 'nil' then
    func = function()
      callable()
    end
  else
    func = function()
      callable(args)
    end
  end
  return func
end

function map(modes, keybinds, callable, description, silent)
  silent = silent or false
  local func
  if type(callable) == 'function' then
    func = wrap(callable)
  else
    func = wrap(callable.callback, callable.args)
  end
  vim.keymap.set(modes, keybinds, func, { desc = description })
end

local picker = Snacks.picker
local toggle = Snacks.toggle
local notifier = Snacks.notifier

map('n', '<leader>m', Snacks.dashboard.open, 'Open [M]ain [M]enu', false)

-- Pickers (snacks.picker)
map('n', 'gd', picker.lsp_definitions, 'Goto Definition')
map('n', 'gD', picker.lsp_declarations, '[G]oto [D]eclaration')

-- Search Pickers (snacks.picker)
map('n', '<leader>sr', picker.lsp_references, '[S]earch [R]eferences')
map('n', '<leader>sh', picker.help, '[S]earch [H]elp')
map('n', '<leader>sk', picker.keymaps, '[S]earch [K]eymaps')
map('n', '<leader>sf', picker.files, '[S]earch [F]iles')
map('n', '<leader>ss', picker.pickers, '[S]earch [S]elect Picker')
map('n', '<leader>sd', picker.diagnostics, '[S]earch [D]iagnostics')
map('n', '<leader>sb', picker.buffers, '[S]earch [B]uffers')
map('n', '<leader>so', picker.lsp_symbols, '[S]earch Document [O]utline')
map('n', '<leader>sl', picker.lines, '[S]earch [L]ines in buffer')
map('n', '<leader>sg', {
  callback = picker.grep,
  args = { cwd = vim.fn.getcwd() },
}, '[S]earch [G]rep in cwd')

-- Snacks toggles
toggle.diagnostics():map '<leader>td'
toggle.treesitter():map '<leader>tT'
toggle.inlay_hints():map '<leader>th'

toggle.option('relativenumber', { name = 'Toggle relative line Numbers' }):map '<leader>tl'

toggle
  .new({
    name = 'Toggle Autoformat',
    get = function()
      return not vim.g.disable_autoformat
    end,
    set = function(state)
      vim.g.disable_autoformat = not state
    end,
  })
  :map '<leader>tf'

-- Snacks notifier
map('n', '<leader>nn', notifier.show_history, 'Notification History')
map('n', '<leader>nd', notifier.hide, 'Dismiss All Notifications')
