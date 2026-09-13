local map = vim.keymap.set

-- Standard mappings
map('n', '<Esc>', '<cmd>nohlsearch<CR>', { desc = 'Clear search highlight' })
map('n', '<leader>e', vim.diagnostic.open_float, { desc = 'Show diagnostic [E]rror messages' })
map('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })
-- Plain <C-c> in insert mode exits without applying a blockwise-visual
-- append/insert (A/I) to the other selected lines, and skips InsertLeave.
-- Make it behave exactly like <Esc> instead.
map('i', '<C-c>', '<Esc>', { desc = 'Exit insert mode (same as Esc)' })

-- Disable natives that are either unused (hard-wrap text formatting, plain
-- number inc/dec superseded by dial.nvim's <leader>k/<leader>j, word-end/
-- search-match motions we don't use) or risky to hit by accident (Ex mode).
-- desc = 'which_key_ignore' is which-key's convention for "mapped, but don't
-- clutter the popup with it" -- these still work as real <Nop> mappings.
local function disable(modes, lhs)
  map(modes, lhs, '<Nop>', { desc = 'which_key_ignore' })
end
disable({ 'n', 'v' }, 'gq') -- hard-wrap format
disable({ 'n', 'v' }, 'gw') -- hard-wrap format, keep cursor
disable({ 'n', 'v' }, 'ge') -- backward to end of word
disable({ 'n', 'v' }, '<C-a>') -- increment
disable({ 'n', 'v' }, '<C-x>') -- decrement
disable('n', 'Q') -- Ex mode
disable('n', 'gn') -- select next search match
disable('n', 'gN') -- select previous search match
disable({ 'n', 'v' }, 'g?') -- ROT13
disable({ 'n', 'v' }, 'g%') -- matchit reverse cycle (cycle is too small to be useful)
disable('n', 'q:') -- command-line history window
disable('n', 'q/') -- search history window (/)
disable('n', 'q?') -- search history window (?)
disable('n', 'zb') -- scroll cursor line to bottom
disable('n', 'ze') -- scroll cursor to right edge (nowrap only)
disable('n', 'zg') -- mark word as good spelling
disable('n', 'zH') -- scroll half-screen left (nowrap only)
disable('n', 'zi') -- toggle 'foldenable'
disable('n', 'zL') -- scroll half-screen right (nowrap only)
disable('n', 'zM') -- close all folds (superseded by ufo's zm)
disable('n', 'zs') -- scroll cursor to left edge (nowrap only)
disable('n', 'zt') -- scroll cursor line to top
disable('n', 'zw') -- mark word as bad spelling
disable('n', 'z<CR>') -- scroll cursor to top + first non-blank
disable('n', 'z=') -- spelling suggestions
disable('n', 'gt') -- next tab page
disable('n', 'gT') -- previous tab page
disable('n', 'zr') -- open one fold level (no-op under ufo's fold state, not foldlevel)
disable({ 'n', 'v', 'x', 'o' }, 'g[') -- mini.ai: move to left edge of "around" textobject
disable({ 'n', 'v', 'x', 'o' }, 'g]') -- mini.ai: move to right edge of "around" textobject
disable('v', '<C-w>') -- window-switch prefix (redundant with normal-mode <C-hjkl>)
disable({ 'v', 'x' }, 'gx') -- open URL/file under selection (redundant with normal-mode gx)
disable('n', 'zf') -- create fold from a motion (superseded by visual zf)
-- [n/]n/[N/]N were never actually functional in any mode -- no real mapping
-- exists (native fallback is nothing); the popup was showing which-key's
-- generic preset text for a convention this config never wired up.
disable({ 'n', 'v', 'o' }, '[n')
disable({ 'n', 'v', 'o' }, ']n')
disable({ 'n', 'v', 'o' }, '[N')
disable({ 'n', 'v', 'o' }, ']N')
disable({ 'n', 'v' }, '[m') -- previous start of method/function (brace heuristic)
disable({ 'n', 'v' }, ']m') -- next start of method/function
disable({ 'n', 'v' }, '[M') -- previous end of method/function
disable({ 'n', 'v' }, ']M') -- next end of method/function
disable({ 'n', 'v' }, '[[') -- previous section start (superseded by Snacks outline)
disable({ 'n', 'v' }, ']]') -- next section start
disable({ 'n', 'v' }, '[]') -- previous section end
disable({ 'n', 'v' }, '][') -- next section end
-- Comment.nvim's own hardcoded block-comment keys (see plugins/comment.lua) --
-- config alone can't suppress just these while keeping toggler/opleader.line.
disable({ 'n', 'v' }, 'gb')
disable('n', 'gbc')
disable({ 'n', 'v' }, 'g`') -- exact-position mark jump w/o jumplist entry (awkward on this layout; plain g' stays)
disable({ 'n', 'v' }, '[%') -- matchit outward jump (redundant given other block/nav coverage)
disable({ 'n', 'v' }, ']%')
disable({ 'n', 'v' }, 'gu') -- lowercase (moved to <leader>u)
disable({ 'n', 'v' }, 'gU') -- uppercase (moved to <leader>U)
disable({ 'n', 'v' }, 'g~') -- toggle case (moved to <leader>~)

-- Case operators, moved off g (which is otherwise "goto" in this config).
-- RHS is the real 'gu'/'gU'/'g~' keys fed with noremap semantics (the
-- default), so they hit the native operator directly instead of recursing
-- into the disable() mappings just above for the same keys.
map({ 'n', 'v' }, '<leader>u', 'gu', { desc = 'Lowercase' })
map({ 'n', 'v' }, '<leader>U', 'gU', { desc = 'Uppercase' })
map({ 'n', 'v' }, '<leader>~', 'g~', { desc = 'Toggle case' })

-- 'n' deliberately excluded here: aB/iB only ever mean anything as text
-- objects (visual/operator-pending), never standalone in normal mode. Adding
-- it made plain 'a'/'i' (enter insert mode) ambiguous against 'aB'/'iB' as a
-- longer prefix, forcing Vim to wait out timeoutlen before committing to the
-- plain keypress -- the cause of "i/a feels laggy to enter insert mode".
disable({ 'v', 'o' }, 'aB') -- native alias for a{ -- confusing, use a{ directly
disable({ 'v', 'o' }, 'iB') -- native alias for i{ -- confusing, use i{ directly

-- Paragraph motion, moved off {/} (awkward on this keyboard layout) onto
-- gp/gP (their native paste-after-cursor meaning given up -- too subtle a
-- distinction from plain p/P to be worth keeping). Fits the "g = goto"
-- scheme, and matches lowercase-forward/uppercase-reverse like ;/, above.
-- RHS is the literal native motion char under noremap semantics.
map({ 'n', 'v', 'o' }, 'gp', '}', { desc = 'Next paragraph' })
map({ 'n', 'v', 'o' }, 'gP', '{', { desc = 'Previous paragraph' })

-- German keyboard: ';' and ',' share a physical key, ';' being the shift
-- variant -- but native Vim has it backwards from every other shifted-pair
-- convention (f/F, t/T, n/N: shift = reverse direction). Swap them so the
-- shifted key (;) is the reverse-direction repeat, matching that pattern.
-- RHS is the other key's literal, real command under noremap semantics, so
-- each hits the other's native behavior directly rather than each other's
-- (which would just be a no-op swap).
map({ 'n', 'v', 'o' }, ';', ',', { desc = 'Repeat last f/t/F/T (reverse direction)' })
map({ 'n', 'v', 'o' }, ',', ';', { desc = 'Repeat last f/t/F/T (same direction)' })

-- Animated half/full-page scroll (snacks.nvim scroll module, opt-in only —
-- see plugins/snacks.lua). The buffer flag is reset on a delay rather than
-- immediately after, since WinScrolled (which triggers the animation) fires
-- after this function returns, not synchronously within it; the delay must
-- outlast the animation (120ms/30ms above) or a mid-animation reset aborts it.
local function animated_scroll(keys)
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
map('n', '<C-d>', animated_scroll '<C-d>', { desc = 'Scroll down half page (animated)' })
map('n', '<C-u>', animated_scroll '<C-u>', { desc = 'Scroll up half page (animated)' })
map('n', '<C-f>', animated_scroll '<C-f>', { desc = 'Scroll down full page (animated)' })
map('n', '<C-b>', animated_scroll '<C-b>', { desc = 'Scroll up full page (animated)' })

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
map('n', '<leader>sb', function()
  Snacks.picker.buffers()
end, { desc = '[S]earch [B]uffers' })
map('n', '<leader>so', function()
  Snacks.picker.lsp_symbols()
end, { desc = '[S]earch Document [O]utline' })
map('n', '<leader>sg', function()
  Snacks.picker.grep { cwd = vim.fn.getcwd() }
end, { desc = '[S]earch [G]rep in cwd' })
map('n', '<leader>sl', function()
  Snacks.picker.lines()
end, { desc = '[S]earch [L]ines in buffer' })
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
Snacks.toggle.diagnostics():map '<leader>td'
Snacks.toggle.treesitter():map '<leader>tT'
Snacks.toggle.inlay_hints():map '<leader>th'
Snacks.toggle
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
-- <leader>n itself is not bound (leaving it as a leaf command previously
-- caused a timeoutlen wait/ambiguity against <leader>nd) -- both actions
-- live one level deeper under the group instead.
map('n', '<leader>nn', function()
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
-- 'A' in visual mode is mapped for charwise/linewise selection (select whole
-- file); blockwise (<C-v>) has its own native meaning (append after the
-- block on every selected line) that this must not shadow. There's no
-- separate map-mode for "visual but not blockwise", so branch on mode() at
-- expr-eval time and fall through to native 'A' for blockwise specifically.
-- Returned as noremap (default), so the fallthrough 'A' hits the built-in
-- command rather than recursing into this same mapping.
map('v', 'A', function()
  if vim.fn.mode() == '\22' then
    return 'A'
  end
  return '<Esc>gg0vG$'
end, { expr = true, desc = 'Select whole file', silent = true })
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
