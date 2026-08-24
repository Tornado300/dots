-- which-key.nvim: shows a popup of available keymaps after a prefix key
-- (e.g. <leader>) is pressed and held past timeoutlen. Most built-in preset
-- groups (windows, g-prefix, motions, text objects, z-prefix) are disabled
-- below — only the fold (z*) keys are manually listed.
-- https://github.com/folke/which-key.nvim
return {
  'folke/which-key.nvim',
  event = 'VimEnter',
  opts = {
    plugins = {
      presets = {
        operators = false,
        motions = false,
        text_objects = false,
        windows = false,
        nav = false,
        z = false,
        g = false,
      },
    },
  },
  config = function(_, opts)
    local wk = require 'which-key'
    wk.setup(opts)
    wk.add {
      { 'za', desc = 'Toggle fold' },
      { 'zA', desc = 'Toggle fold (recursive)' },
      { 'zo', desc = 'Open fold' },
      { 'zO', desc = 'Open fold (recursive)' },
      { 'zc', desc = 'Close fold' },
      { 'zC', desc = 'Close fold (recursive)' },
      { 'zj', desc = 'Next fold' },
      { 'zk', desc = 'Previous fold' },
      { 'zr', desc = 'Open one fold level' },
      { 'zv', desc = 'Reveal cursor' },
    }
  end,
}
