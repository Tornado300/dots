-- conform.nvim: format-on-save and <leader>f, dispatching to per-filetype
-- formatters (stylua, ruff_format, prettier, ...), falling back to the LSP.
-- https://github.com/stevearc/conform.nvim
return {
  'stevearc/conform.nvim',
  lazy = false,
  keys = {
    {
      '<leader>f',
      function()
        require('conform').format { async = true, lsp_fallback = true }
      end,
      mode = '',
      desc = '[F]ormat buffer',
    },
  },
  opts = {
    notify_on_error = true,
    format_on_save = function(bufnr)
      local disable_filetypes = { c = true, cpp = true }
      return {
        timeout_ms = 500,
        lsp_fallback = not disable_filetypes[vim.bo[bufnr].filetype],
      }
    end,
    formatters = {
      -- Raise the default max line length (these tools' own defaults are 80-120,
      -- which wraps too eagerly). These override a project's own .stylua.toml/
      -- .prettierrc/pyproject.toml if it sets its own width.
      -- ruff needs append_args: its args start with the "format" subcommand, and
      -- ruff's CLI parser rejects --line-length appearing before that subcommand.
      stylua = { prepend_args = { '--column-width', '160' } },
      ruff_format = { append_args = { '--line-length', '160' } },
      prettier = { prepend_args = { '--print-width', '160' } },
    },
    formatters_by_ft = {
      lua = { 'stylua' },
      python = { 'ruff_format' },
      d2 = { 'd2' },
      xml = { 'xmllint' },
      html = { 'prettier' },
      css = { 'prettier' },
      scss = { 'prettier' },
      less = { 'prettier' },
      javascript = { 'prettier' },
      javascriptreact = { 'prettier' },
      typescript = { 'prettier' },
      typescriptreact = { 'prettier' },
      json = { 'prettier' },
    },
  },
}
