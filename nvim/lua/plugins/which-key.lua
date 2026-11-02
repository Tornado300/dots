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
    wk.add {
      -- Clearer wording than which-key's own preset text.
      { 'w', mode = { 'n', 'v' }, desc = 'Next word' },
      { 'W', mode = { 'n', 'v' }, desc = 'Next WORD' },
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
      { 'Y', desc = 'Yank to end of line' },
      { '<leader>n', group = 'Notifications' },
      -- swapped, see keybinds.lua -- correct the preset's stale text
      { ';', mode = { 'n', 'v', 'o' }, desc = 'Repeat last f/t/F/T (reverse direction)' },
      { ',', mode = { 'n', 'v', 'o' }, desc = 'Repeat last f/t/F/T (same direction)' },
      { 'n', mode = { 'n', 'v' }, desc = 'Repeat last search (same direction)' },
      { 'N', mode = { 'n', 'v' }, desc = 'Repeat last search (reverse direction)' },
      { '&', desc = 'Repeat last :s on current line' },
      { '.', desc = 'Repeat last change' },
      { '@:', desc = 'Repeat last Ex (:) command' },
      { '@@', desc = 'Repeat last-run macro' },
      { 'J', mode = { 'n', 'v' }, desc = 'Join lines (with space)' },
      { 'gJ', mode = { 'n', 'v' }, desc = 'Join lines (no space)' },
      { 'R', desc = 'Enter Replace mode' },
      { 'u', desc = 'Undo' },
      { '<C-r>', desc = 'Redo' },
      { '@', mode = 'v', desc = 'Run macro on every selected line' },
      { '#', mode = 'v', desc = 'Search backward for the current selection' },
      { '*', mode = 'v', desc = 'Search forward for the current selection' },
    }
  end,
}
