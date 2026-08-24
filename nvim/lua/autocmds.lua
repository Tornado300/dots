-- Autocommands, filetype detection, diagnostic config, and user commands
-- that don't belong to any single plugin.

-- Highlight the yanked region briefly after copying
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
  callback = function()
    vim.highlight.on_yank()
  end,
})

-- Filetype detection for file types Neovim doesn't recognize by default
vim.filetype.add { pattern = { ['.*/hypr/.*%.conf'] = 'hyprlang' } }
vim.filetype.add { pattern = { ['.*%.rasi'] = 'css' } }
vim.filetype.add { pattern = { ['.*%.mcfunction'] = 'mcfunction' } }
vim.filetype.add { extension = { mcdoc = 'mcdoc' } }
vim.filetype.add { extension = { d2 = 'd2' } }
vim.filetype.add { extension = { kml = 'xml' } }

-- Reserve `g` for navigation: drop the non-movement built-ins that Neovim 0.11 adds.
-- `grr` (references) and `gO` (document symbols) are also dropped here — replaced by
-- `gr` (Snacks references picker, keybinds.lua) and <leader>so (Snacks symbols picker)
-- respectively, so there's exactly one way to reach each instead of two.
for _, lhs in ipairs { 'gc', 'gcc', 'gra', 'grn', 'grx', 'grr', 'gO' } do
  pcall(vim.keymap.del, 'n', lhs)
  pcall(vim.keymap.del, 'x', lhs)
end

vim.diagnostic.config {
  severity_sort = true,
  underline = true,
  update_in_insert = false,
  virtual_text = false,
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = 'E',
      [vim.diagnostic.severity.WARN] = 'W',
      [vim.diagnostic.severity.INFO] = 'I',
      [vim.diagnostic.severity.HINT] = 'H',
    },
  },
}

-- :Chcwd — cd to the current file's directory
vim.api.nvim_create_user_command('Chcwd', function()
  local dir = vim.fn.expand '%:p:h'
  if dir ~= '' then
    vim.cmd('cd ' .. vim.fn.fnameescape(dir))
    print('cwd → ' .. vim.fn.getcwd())
  end
end, {})

-- Remember cursor/fold/scroll position per file: save it on leave, restore it on reopen
local view_group = vim.api.nvim_create_augroup('auto-view', { clear = true })
vim.api.nvim_create_autocmd({ 'BufWinLeave', 'BufWritePost', 'WinLeave' }, {
  desc = 'Save view (cursor/folds) for real files',
  group = view_group,
  callback = function(args)
    if vim.b[args.buf].view_activated then
      vim.cmd.mkview { mods = { emsg_silent = true } }
    end
  end,
})
vim.api.nvim_create_autocmd('BufWinEnter', {
  desc = 'Restore view (cursor/folds) for real files',
  group = view_group,
  callback = function(args)
    if vim.b[args.buf].view_activated then
      return
    end
    local filetype = vim.api.nvim_get_option_value('filetype', { buf = args.buf })
    local buftype = vim.api.nvim_get_option_value('buftype', { buf = args.buf })
    local ignore_filetypes = { 'gitcommit', 'gitrebase', 'svg', 'hgcommit' }
    if buftype == '' and filetype ~= '' and not vim.tbl_contains(ignore_filetypes, filetype) then
      vim.b[args.buf].view_activated = true
      vim.cmd.loadview { mods = { emsg_silent = true } }
    end
  end,
})
