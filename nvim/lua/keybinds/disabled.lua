-- Disable natives that are either unused or risky to hit by accident (Ex mode).
-- desc = 'which_key_ignore' is which-key's convention for "mapped, but don't
-- clutter the popup with it" -- these still work as real <Nop> mappings.

local which_key = require 'which-key'

local function disable(modes, lhs_list)
  for _, lhs in ipairs(lhs_list) do
    vim.keymap.set(modes, lhs, '<Nop>', { desc = 'which_key_ignore' })
    which_key.add { lhs, mode = modes, hidden = true }
  end
end

-- replaced by <leader>d
disable('n', { 'K' })

-- native default: show diagnostics under cursor (redundant with <leader>e)
disable('n', { '<C-w>d' })

-- duplicate of ' and hard to reach
disable('n', { '`' })

-- Ex mode
-- command-line history window
-- search history window (/), (?)
disable('n', { 'Q', 'q:', 'q/', 'q?' })

-- select next/previous search match
-- next/previous tab page
-- Comment.nvim's own hardcoded block-comment keys (see plugins/comment.lua) --
-- repeat last :s over whole file -- unused, and doesn't fit the 'g = goto' scheme anyway
disable('n', { 'gn', 'gN', 'gT', 'gt', 'gbc', 'g&' })

-- open one fold level (no-op under ufo's fold state, not foldlevel)
-- spelling suggestions
-- scroll cursor to top + first non-blank
-- mark word as bad spelling
-- scroll cursor line to top
-- scroll cursor to left edge (nowrap only)
-- close all folds (superseded by ufo's zm)
-- scroll half-screen right (nowrap only)
-- toggle 'foldenable'
-- scroll half-screen left (nowrap only)
-- mark word as good spelling
-- scroll cursor to right edge (nowrap only)
-- scroll cursor line to bottom
-- create fold from a motion (superseded by visual zf)
disable('n', { 'zr', 'z=', 'z<CR>', 'zw', 'zt', 'zs', 'zM', 'zL', 'zi', 'zH', 'zg', 'ze', 'zb', 'zf' })

-- jump to previous/next/first/last diagnostic, spelling, etc.
disable('n', { '[d', ']d', '[D', ']D', '[', ']' })

-- ############################################# --
-- ############################################# --

-- window-switch prefix
disable('v', { '<C-w>' })

-- redundant and not used
disable('v', { 'Q' })

-- ############################################# --
-- ############################################# --

-- hard-wrap format
-- hard-wrap format, keep cursor
-- backward to end of word
-- ROT13
-- matchit reverse cycle
-- Comment.nvim's own hardcoded block-comment keys (see plugins/comment.lua) --
-- exact-position mark jump w/o jumplist entry
-- lowercase (moved to <leader>u)
-- uppercase (moved to <leader>U)
-- toggle case (moved to <leader>~)
disable({ 'n', 'v' }, { 'gq', 'gw', 'ge', 'g?', 'g%', 'gb', 'g`', 'gu', 'gU', 'g~' })

-- increment/decrement
disable({ 'n', 'v' }, { '<C-a>', '<C-x>' })

-- previous/next start of method/function (brace heuristic)
-- previous/next end of method/function
-- previous/next section start (superseded by Snacks outline)
-- previous/next section end
-- matchit outward jump (redundant given other block/nav coverage)
disable({ 'n', 'v', 'o' }, { '[m', ']m', '[M', ']M', '[[', ']]', '[]', '][', '[%', ']%' })

-- ############################################# --
-- ############################################# --

-- mini.ai: move to left/right edge of "around" textobject
disable({ 'n', 'v', 'x', 'o' }, { 'g[', 'g]' })

-- open URL/file under selection (redundant with normal-mode gx)
disable({ 'v', 'x' }, { 'gx' })

-- [n/]n/[N/]N were never actually functional in any mode; the popup was showing which-key's presets
disable({ 'n', 'v', 'o' }, { '[n', ']n', '[N', ']N' })

-- 'n' deliberately excluded here: aB/iB only ever mean anything as text
-- objects (visual/operator-pending), never standalone in normal mode. Adding
-- it made plain 'a'/'i' (enter insert mode) ambiguous against 'aB'/'iB' as a
-- longer prefix, forcing Vim to wait out timeoutlen before committing to the
-- plain keypress -- the cause of "i/a feels laggy to enter insert mode".
-- native alias for a{ i{ -- confusing, use a{ i{ directly
disable({ 'v', 'o' }, { 'aB', 'iB' })
