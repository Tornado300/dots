vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.mouse = 'a'

vim.opt.showmode = false
vim.opt.clipboard = 'unnamedplus'
vim.opt.breakindent = true
vim.opt.undofile = true

-- Case-insensitive search unless \C or a capital letter appears in the pattern
vim.opt.ignorecase = true
vim.opt.smartcase = true

vim.opt.signcolumn = 'yes'
vim.opt.updatetime = 250
vim.opt.timeoutlen = 300
vim.opt.splitright = true
vim.opt.splitbelow = true

vim.opt.list = true
vim.opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' }

vim.opt.inccommand = 'split'
vim.opt.cursorline = true
vim.opt.scrolloff = 10
vim.opt.hlsearch = true

vim.opt.confirm = true
vim.opt.smoothscroll = true
vim.opt.winborder = 'rounded'
vim.opt.pumheight = 20

-- Folding (nvim-ufo takes over; these are the required foundation)
vim.opt.foldcolumn = '0'
vim.opt.foldlevel = 99
vim.opt.foldlevelstart = 99
vim.opt.foldenable = true

vim.cmd [[
  cnoreabbrev <expr> s getcmdtype() == ':' && getcmdline() == 's' ? 's/\v' : 's'
]]
