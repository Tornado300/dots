-- which-key.nvim: shows a popup of available keymaps after a prefix key
-- (e.g. <leader>) is pressed and held past timeoutlen. All built-in preset
-- groups (windows, g-prefix, motions, text objects, z-prefix) are enabled,
-- so every native Vim command gets a description here too, not just our
-- own mappings -- plus a few extra fold keys the presets don't cover.
-- https://github.com/folke/which-key.nvim
return {
  'folke/which-key.nvim',
  event = 'VimEnter',
  opts = {
    plugins = {
      presets = {
        operators = true,
        motions = true,
        text_objects = true,
        windows = true,
        nav = true,
        z = true,
        g = true,
      },
    },
  },
  config = function(_, opts)
    local wk = require 'which-key'
    wk.setup(opts)
    wk.add {
      { 'zd', desc = 'Delete fold under cursor' },
      { 'zD', desc = 'Delete fold under cursor (recursive)' },
      { 'zE', desc = 'Eliminate all manual folds in window' },
    }
    -- A key mapped to <Nop> (see the disable() calls in keybinds.lua) is
    -- treated by which-key as a "virtual" mapping, and its desc='which_key_
    -- ignore' is never actually converted to a hide -- that conversion only
    -- happens for entries registered here via wk.add(). Keys that also have
    -- a built-in preset (ge, gn, gN, g%, gw) would otherwise show the
    -- preset's original description as if the key still did that.
    wk.add {
      -- mode defaults to normal only; anything also disabled in visual mode
      -- (see the {'n','v'} disable() calls in keybinds.lua) needs its own
      -- entry here too, or the visual-mode popup still shows the preset.
      { 'gq', mode = { 'n', 'v' }, hidden = true },
      { 'gw', mode = { 'n', 'v' }, hidden = true },
      { 'ge', mode = { 'n', 'v' }, hidden = true },
      { 'gn', hidden = true },
      { 'gN', hidden = true },
      { 'g%', mode = { 'n', 'v' }, hidden = true },
      { 'g?', mode = { 'n', 'v' }, hidden = true },
      { 'Q', hidden = true },
      { '<C-a>', mode = { 'n', 'v' }, hidden = true },
      { '<C-x>', mode = { 'n', 'v' }, hidden = true },
      { 'q:', hidden = true },
      { 'q/', hidden = true },
      { 'q?', hidden = true },
      { 'zb', hidden = true },
      { 'ze', hidden = true },
      { 'zg', hidden = true },
      { 'zH', hidden = true },
      { 'zi', hidden = true },
      { 'zL', hidden = true },
      { 'zM', hidden = true },
      { 'zs', hidden = true },
      { 'zt', hidden = true },
      { 'zw', hidden = true },
      { 'z<CR>', hidden = true },
      { 'z=', hidden = true },
      { 'gt', hidden = true },
      { 'gT', hidden = true },
      { 'zr', hidden = true },
      { 'g[', mode = { 'n', 'v' }, hidden = true },
      { 'g]', mode = { 'n', 'v' }, hidden = true },
      { '<C-w>', mode = 'v', hidden = true },
      { 'gx', mode = 'v', hidden = true },
      { 'zf', mode = 'n', hidden = true }, -- visual zf (vzf) stays visible
      { 'Q', mode = 'v', hidden = true }, -- no default meaning in visual mode
      { '[n', mode = { 'n', 'v', 'o' }, hidden = true },
      { ']n', mode = { 'n', 'v', 'o' }, hidden = true },
      { '[N', mode = { 'n', 'v', 'o' }, hidden = true },
      { ']N', mode = { 'n', 'v', 'o' }, hidden = true },
      { '[m', mode = { 'n', 'v' }, hidden = true },
      { ']m', mode = { 'n', 'v' }, hidden = true },
      { '[M', mode = { 'n', 'v' }, hidden = true },
      { ']M', mode = { 'n', 'v' }, hidden = true },
      { '[[', mode = { 'n', 'v' }, hidden = true },
      { ']]', mode = { 'n', 'v' }, hidden = true },
      { '[]', mode = { 'n', 'v' }, hidden = true },
      { '][', mode = { 'n', 'v' }, hidden = true },
      -- These four are which-key preset entries with no real binding at
      -- all -- verified against Neovim's own docs (:h motion.txt): the
      -- actual native pairs are [(<->]) and [{<->]}, not [<->](/][{->]{,
      -- and there's no native [< /]< bracket motion. which-key's preset
      -- table documents them anyway (a mismatch on its end); hiding them
      -- since nothing backs them here.
      { '[<', hidden = true },
      { ']<', hidden = true },
      { '](', hidden = true },
      { ']{', hidden = true },
      { 'gb', mode = { 'n', 'v' }, hidden = true },
      { 'gbc', mode = 'n', hidden = true },
      { 'g`', mode = { 'n', 'v' }, hidden = true },
      { '[%', mode = { 'n', 'v' }, hidden = true },
      { ']%', mode = { 'n', 'v' }, hidden = true },
      -- v/V just switch visual sub-mode -- real and functional, but not
      -- worth a popup entry (self-referential: "press v to get to visual
      -- mode" while already in visual mode).
      { 'v', mode = 'v', hidden = true },
      { 'V', mode = 'v', hidden = true },
      -- Clearer wording than which-key's own preset text.
      { 'w', mode = { 'n', 'v' }, desc = 'Next word (stops at punctuation)' },
      { 'W', mode = { 'n', 'v' }, desc = 'Next WORD (whitespace-delimited only)' },
      { 'a(', mode = { 'n', 'v', 'o' }, desc = 'Around ( ) block' },
      { 'a)', mode = { 'n', 'v', 'o' }, desc = 'Around ( ) block' },
      { 'i(', mode = { 'n', 'v', 'o' }, desc = 'Inside ( ) block' },
      { 'i)', mode = { 'n', 'v', 'o' }, desc = 'Inside ( ) block' },
      { 'a[', mode = { 'n', 'v', 'o' }, desc = 'Around [ ] block' },
      { 'a]', mode = { 'n', 'v', 'o' }, desc = 'Around [ ] block' },
      { 'i[', mode = { 'n', 'v', 'o' }, desc = 'Inside [ ] block' },
      { 'i]', mode = { 'n', 'v', 'o' }, desc = 'Inside [ ] block' },
      { 'a{', mode = { 'n', 'v', 'o' }, desc = 'Around { } block' },
      { 'a}', mode = { 'n', 'v', 'o' }, desc = 'Around { } block' },
      { 'i{', mode = { 'n', 'v', 'o' }, desc = 'Inside { } block' },
      { 'i}', mode = { 'n', 'v', 'o' }, desc = 'Inside { } block' },
      { 'ab', mode = { 'n', 'v', 'o' }, desc = 'Around any bracket: ( [ {' },
      { 'ib', mode = { 'n', 'v', 'o' }, desc = 'Inside any bracket: ( [ {' },
      { 'aB', mode = { 'v', 'o' }, hidden = true }, -- alias for a{, confusing -- use a{ directly
      { 'iB', mode = { 'v', 'o' }, hidden = true }, -- alias for i{, confusing -- use i{ directly
      { 'gu', mode = { 'n', 'v' }, hidden = true }, -- moved to <leader>u
      { 'gU', mode = { 'n', 'v' }, hidden = true }, -- moved to <leader>U
      { 'g~', mode = { 'n', 'v' }, hidden = true }, -- moved to <leader>~
      { '<leader>n', group = 'Notifications' },
      -- swapped, see keybinds.lua -- correct the preset's stale text
      { ';', mode = { 'n', 'v', 'o' }, desc = 'Repeat last f/t/F/T (reverse direction)' },
      { ',', mode = { 'n', 'v', 'o' }, desc = 'Repeat last f/t/F/T (same direction)' },
      -- which-key's preset table doesn't cover this whole repeat/undo/join
      -- family at all (checked its source directly) -- not fake, just
      -- outside what it documents by default.
      { 'n', mode = { 'n', 'v' }, desc = 'Repeat last search (same direction)' },
      { 'N', mode = { 'n', 'v' }, desc = 'Repeat last search (reverse direction)' },
      { '&', desc = 'Repeat last :s on current line' },
      { 'g&', desc = 'Repeat last :s on whole file, same flags' },
      { '.', desc = 'Repeat last change' },
      { '@:', desc = 'Repeat last Ex (:) command' },
      { '@@', desc = 'Repeat last-run macro' },
      { 'J', mode = { 'n', 'v' }, desc = 'Join lines (with space)' },
      { 'gJ', mode = { 'n', 'v' }, desc = 'Join lines (no space)' },
      { 'R', desc = 'Enter Replace mode' },
      { 'u', desc = 'Undo' },
      { '<C-r>', desc = 'Redo' },
    }
  end,
}
