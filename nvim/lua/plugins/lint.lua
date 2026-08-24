-- nvim-lint: async linting outside the LSP pipeline. Only markdown is wired
-- up (markdownlint-cli2, the actively maintained successor to markdownlint-cli)
-- — extend linters_by_ft below if you want more.
-- https://github.com/mfussenegger/nvim-lint
return {
  'mfussenegger/nvim-lint',
  event = { 'BufReadPre', 'BufNewFile' },
  config = function()
    local lint = require 'lint'
    lint.linters_by_ft = {
      markdown = { 'markdownlint-cli2' },
    }

    local lint_augroup = vim.api.nvim_create_augroup('lint', { clear = true })
    vim.api.nvim_create_autocmd({ 'BufEnter', 'BufWritePost', 'InsertLeave' }, {
      group = lint_augroup,
      callback = function()
        require('lint').try_lint()
      end,
    })
  end,
}
