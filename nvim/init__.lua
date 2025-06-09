
vim.cmd [[
  syntax on
  filetype plugin indent on
  colorscheme default
]]
vim.filetype.add { pattern = { ['.*%.mcfunction'] = 'mcfunction' } }
