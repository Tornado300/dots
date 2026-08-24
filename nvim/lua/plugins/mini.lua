-- mini.nvim: only three submodules enabled here — mini.ai (better text
-- objects, e.g. `dip`/`vaf`), mini.surround (add/change/delete surrounding
-- pairs), mini.statusline (the statusline itself).
-- https://github.com/echasnovski/mini.nvim
return {
  'echasnovski/mini.nvim',
  config = function()
    require('mini.ai').setup { n_lines = 500 }
    require('mini.surround').setup()

    local statusline = require 'mini.statusline'
    statusline.setup { use_icons = vim.g.have_nerd_font }
    ---@diagnostic disable-next-line: duplicate-set-field
    statusline.section_location = function()
      return '%2l:%-2v'
    end
  end,
}
