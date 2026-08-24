local map = vim.keymap.set

-- Standard mappings
map('n', '<Esc>', '<cmd>nohlsearch<CR>', { desc = 'Clear search highlight' })
map('n', '<leader>e', vim.diagnostic.open_float, { desc = 'Show diagnostic [E]rror messages' })
map('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

-- Window navigation
map('n', '<C-h>', '<C-w><C-h>', { desc = 'Move focus to the left window' })
map('n', '<C-l>', '<C-w><C-l>', { desc = 'Move focus to the right window' })
map('n', '<C-j>', '<C-w><C-j>', { desc = 'Move focus to the lower window' })
map('n', '<C-k>', '<C-w><C-k>', { desc = 'Move focus to the upper window' })

-- LSP
map('n', '<leader>r', vim.lsp.buf.rename, { desc = 'Rename variable under cursor' })
map({ 'n', 'x' }, '<leader>a', vim.lsp.buf.code_action, { desc = 'Code [A]ction' })
map('n', '<leader>d', vim.lsp.buf.hover, { desc = 'Hover Documentation' })
map('n', 'gD', vim.lsp.buf.declaration, { desc = 'Goto Declaration' })

-- Pickers (snacks.picker)
map('n', '<leader>sr', function()
  Snacks.picker.lsp_references()
end, { desc = '[S]earch [R]eferences' })
map('n', '<leader>sh', function()
  Snacks.picker.help()
end, { desc = '[S]earch [H]elp' })
map('n', '<leader>sk', function()
  Snacks.picker.keymaps()
end, { desc = '[S]earch [K]eymaps' })
map('n', '<leader>sf', function()
  Snacks.picker.files()
end, { desc = '[S]earch [F]iles' })
map('n', '<leader>ss', function()
  Snacks.picker.pickers()
end, { desc = '[S]earch [S]elect Picker' })
map('n', '<leader>sd', function()
  Snacks.picker.diagnostics()
end, { desc = '[S]earch [D]iagnostics' })
map('n', '<leader>s.', function()
  Snacks.picker.recent()
end, { desc = '[S]earch Recent Files ("." for repeat)' })
map('n', '<leader>sb', function()
  Snacks.picker.buffers()
end, { desc = '[S]earch [B]uffers' })
map('n', '<leader>so', function()
  Snacks.picker.lsp_symbols()
end, { desc = '[S]earch Document [O]utline' })
map('n', '<leader>sg', function()
  Snacks.picker.grep { cwd = vim.fn.getcwd() }
end, { desc = '[S]earch [G]rep in cwd' })
map('n', 'gd', function()
  Snacks.picker.lsp_definitions()
end, { desc = 'Goto Definition' })

-- Snacks toggles
Snacks.toggle
  .new({
    name = 'Toggle relative line Numbers',
    get = function()
      return vim.wo.relativenumber
    end,
    set = function(state)
      vim.wo.relativenumber = not state
    end,
  })
  :map '<leader>tl'
Snacks.toggle.option('spell', { name = 'Spelling' }):map '<leader>ts'
Snacks.toggle.diagnostics():map '<leader>td'
Snacks.toggle.treesitter():map '<leader>tT'
Snacks.toggle.inlay_hints():map '<leader>th'

-- Snacks notifier
map('n', '<leader>n', function()
  Snacks.notifier.show_history()
end, { desc = 'Notification History' })
map('n', '<leader>nd', function()
  Snacks.notifier.hide()
end, { desc = 'Dismiss All Notifications' })

-- Terminal
map('n', 'T', '<cmd>ToggleTerm<CR>', { desc = 'Toggle terminal' })

-- Run current file in a venv/language-aware terminal. Add an entry here for any
-- other filetype you want <leader>xr to support. Each entry returns the shell
-- commands to run, in order, joined with && (so a failing step stops the chain).
local run_commands = {
  python = function(file)
    return {
      '[ -f ./.venv/bin/activate ] && source ./.venv/bin/activate',
      'python ' .. vim.fn.shellescape(file),
    }
  end,
  javascript = function(file)
    return { 'node ' .. vim.fn.shellescape(file) }
  end,
  typescript = function(file)
    return { 'npx tsx ' .. vim.fn.shellescape(file) }
  end,
  sh = function(file)
    return { 'bash ' .. vim.fn.shellescape(file) }
  end,
  go = function(file)
    return { 'go run ' .. vim.fn.shellescape(file) }
  end,
  lua = function(file)
    return { 'lua ' .. vim.fn.shellescape(file) }
  end,
}

map('n', '<leader>xr', function()
  local runner = run_commands[vim.bo.filetype]
  if not runner then
    vim.notify('No run command configured for filetype: ' .. vim.bo.filetype, vim.log.levels.WARN)
    return
  end
  local file = vim.fn.expand '%:t'
  local dir = vim.fn.expand '%:p:h'
  local cmd = table.concat(runner(file), ' && ')
  require('toggleterm').exec(cmd, nil, nil, dir, nil, nil, false)
end, { desc = '[X] Run current file' })

map('n', '<leader>m', [[:lua Snacks.dashboard.open()<CR>]], { desc = 'Open Main Menu', noremap = true, silent = true })
map('v', 'A', '<Esc>gg0vG$', { desc = 'Select whole file', noremap = true, silent = true })
map({ 'n', 'v' }, 'P', '"0p', { desc = 'Paste from yank register', noremap = true, silent = true })

-- Toggle NeoTree
local function cycle_neotree()
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
vim.keymap.set('n', '<M-h>', cycle_neotree, { desc = 'Cycle Neotree' })

-- toggle diffsplit
vim.keymap.set('n', '<leader>xd', function()
  if vim.wo.diff then
    vim.cmd 'diffoff!'
  else
    vim.cmd 'windo diffthis'
  end
end, { desc = 'Toggle diff view for all splits' })
