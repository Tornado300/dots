-- tokyonight.nvim: colorscheme (night variant).
-- https://github.com/folke/tokyonight.nvim
return {
  'folke/tokyonight.nvim',
  priority = 1000,
  init = function()
    vim.cmd.colorscheme 'tokyonight-night'
    vim.cmd.hi 'Comment gui=none'
  end,
}
