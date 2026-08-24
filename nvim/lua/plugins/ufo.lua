-- nvim-ufo: better folding UI/behavior, backed by treesitter (falls back to
-- indent). zR/zm open/close all folds.
-- https://github.com/kevinhwang91/nvim-ufo
return {
  'kevinhwang91/nvim-ufo',
  dependencies = { 'kevinhwang91/promise-async' },
  lazy = false,
  opts = {
    provider_selector = function(bufnr, ft)
      if ft == '' or ft == 'neo-tree' or vim.bo[bufnr].buftype ~= '' then
        return ''
      end
      return { 'treesitter', 'indent' }
    end,
    open_fold_hl_timeout = 0,
  },
  init = function()
    vim.keymap.set('n', 'zR', function() require('ufo').openAllFolds() end, { desc = 'Open all folds' })
    vim.keymap.set('n', 'zm', function() require('ufo').closeAllFolds() end, { desc = 'Close all folds' })
    vim.api.nvim_create_autocmd({ 'BufReadPost', 'BufNewFile' }, {
      callback = function()
        vim.opt_local.foldlevel = 99
      end,
    })
  end,
}
