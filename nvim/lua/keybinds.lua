local map = vim.keymap.set

-- Standard mappings
map('n', '<Esc>', '<cmd>nohlsearch<CR>', { desc = 'Clear search highlight' })
map('i', '<C-c>', '<Esc>', { desc = 'Exit insert mode (same as Esc)' })
map('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })
-- Single <C-c> still passes through as SIGINT to whatever's running in the
-- terminal; only the doubled form exits terminal mode. Same ambiguous-prefix
-- timing as <Esc><Esc> above -- ttimeoutlen has to elapse before a lone
-- <C-c> is forwarded, so it may feel just as fiddly if pressed slowly.
map('t', '<C-c><C-c>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

map('n', '<leader>e', vim.diagnostic.open_float, { desc = 'Show diagnostic [E]rror messages' })

-- Case operators, moved off g
-- RHS is the real 'gu'/'gU'/'g~' keys fed with noremap semantics,
-- so they hit the native operator directly instead of recursing
-- into the disable() mappings.
map({ 'n', 'v' }, '<leader>u', 'gu', { desc = 'Lowercase' })
map({ 'n', 'v' }, '<leader>U', 'gU', { desc = 'Uppercase' })
map({ 'n', 'v' }, '<leader>~', 'g~', { desc = 'Toggle case' })

-- Paragraph motion, moved off {  } (awkward on this keyboard layout) onto
-- gp/gP (their native paste-after-cursor meaning given up -- too subtle a
-- distinction from plain p/P to be worth keeping).
-- RHS is the literal native motion char under noremap semantics.
map({ 'n', 'v', 'o' }, 'gp', '}', { desc = '[G]oto Next [p]aragraph' })
map({ 'n', 'v', 'o' }, 'gP', '{', { desc = '[G]oto [P]revious paragraph' })

-- German keyboard: ';' and ',' share a physical key, ';' being the shift
-- variant -- but native Vim has it backwards from every other shifted-pair
-- convention (f/F, t/T, n/N: shift = reverse direction). Swap them so the
-- shifted key (;) is the reverse-direction repeat, matching that pattern.
map({ 'n', 'v', 'o' }, ';', ',', { desc = 'Repeat last f/t/F/T (reverse direction)' })
map({ 'n', 'v', 'o' }, ',', ';', { desc = 'Repeat last f/t/F/T (same direction)' })

-- Animated half/full-page scroll (see scroll_animate.lua)
local scroll = require('helpers.scroll_animate').scroll
map('n', '<C-d>', scroll '<C-d>', { desc = 'Scroll [d]own half page' })
map('n', '<C-u>', scroll '<C-u>', { desc = 'Scroll [u]p half page' })
map('n', '<C-f>', scroll '<C-f>', { desc = 'Scroll down full page' })
map('n', '<C-b>', scroll '<C-b>', { desc = 'Scroll up full page' })

-- Window navigation
map('n', '<C-h>', '<C-w><C-h>', { desc = 'Move focus to the left window' })
map('n', '<C-l>', '<C-w><C-l>', { desc = 'Move focus to the right window' })
map('n', '<C-j>', '<C-w><C-j>', { desc = 'Move focus to the lower window' })
map('n', '<C-k>', '<C-w><C-k>', { desc = 'Move focus to the upper window' })

-- LSP
map('n', '<leader>d', vim.lsp.buf.hover, { desc = 'Hover [D]ocumentation' })
map('n', '<leader>r', vim.lsp.buf.rename, { desc = '[R]ename symbol under cursor' })
map({ 'n', 'x' }, '<leader>a', vim.lsp.buf.code_action, { desc = 'Code [A]ction' })

-- Tab switching
-- <Tab> is a terminal-level alias for <C-i>
-- (jump forward in the jumplist) -- unused here, so repurposed.
map('n', '<Tab>', 'gt', { desc = 'Next tab' })
map('n', '<S-Tab>', 'gT', { desc = 'Previous tab' })

-- Terminal (see terminal_tab.lua for the tab-jump logic)
map('n', 'T', require('terminal_tab').toggle, { desc = 'Toggle terminal (own tab)' })

-- Run current file (see file_runner.lua to add filetypes)
map('n', '<leader>xr', require('helpers.file_runner').run, { desc = '[X] Run current file' })

-- map('n', '<leader>m', [[:lua Snacks.dashboard.open()<CR>]], { desc = 'Open Main Menu', noremap = true, silent = true })
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

-- Toggle NeoTree (see neotree_toggle.lua)
map('n', '<M-h>', require('helpers.neotree_toggle').cycle, { desc = 'Cycle Neotree' })

-- toggle diffsplit
vim.keymap.set('n', '<leader>xd', function()
  if vim.wo.diff then
    vim.cmd 'diffoff!'
  else
    vim.cmd 'windo diffthis'
  end
end, { desc = 'Toggle diff view for all splits' })

require 'keybinds.snacks'
require 'keybinds.disabled'
