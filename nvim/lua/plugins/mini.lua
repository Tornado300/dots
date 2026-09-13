-- mini.nvim: only three submodules enabled here — mini.ai (better text
-- objects, e.g. `dip`/`vaf`), mini.surround (add/change/delete surrounding
-- pairs), mini.statusline (the statusline itself).
-- https://github.com/echasnovski/mini.nvim
return {
  'echasnovski/mini.nvim',
  config = function()
    require('mini.ai').setup { n_lines = 500 }
    -- find/find_left (sf/sF, plus their n/l "search next/prev" suffix
    -- variants) removed: redundant with va{/vi{-style selection, which
    -- already finds the nearest surrounding, and native f/F for plain
    -- character search.
    require('mini.surround').setup { mappings = { find = '', find_left = '' } }

    local statusline = require 'mini.statusline'
    statusline.setup { use_icons = vim.g.have_nerd_font }
    ---@diagnostic disable-next-line: duplicate-set-field
    statusline.section_location = function()
      return '%2l:%-2v'
    end
  end,
}
