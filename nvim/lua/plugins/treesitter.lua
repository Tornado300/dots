-- nvim-treesitter: incremental parsing for syntax highlighting, indentation,
-- and everything else (folds, textobjects, context) that reads the parse
-- tree. Installed parsers are listed below.
-- https://github.com/nvim-treesitter/nvim-treesitter
return {
  'nvim-treesitter/nvim-treesitter',
  branch = 'main',
  lazy = false,
  build = ':TSUpdate',
  config = function()
    require('nvim-treesitter').install {
      'bash',
      'c',
      'diff',
      'html',
      'lua',
      'luadoc',
      'markdown',
      'markdown_inline',
      'vim',
      'vimdoc',
      'python',
      'hyprlang',
      'css',
      'scss',
      'toml',
      'query',
      'regex',
      'javascript',
      'typescript',
      'tsx',
      'jsdoc',
      'json',
      'json5',
    }

    vim.api.nvim_create_autocmd('FileType', {
      callback = function(ev)
        pcall(vim.treesitter.start, ev.buf)
        vim.bo[ev.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
      end,
    })
  end,
}
