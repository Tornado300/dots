-- nvim-cmp: autocompletion popup, sourced from LSP, snippets, paths, buffer words.
-- https://github.com/hrsh7th/nvim-cmp
return {
  'hrsh7th/nvim-cmp',
  event = 'InsertEnter',
  dependencies = {
    {
      'L3MON4D3/LuaSnip',
      build = (function()
        if vim.fn.has 'win32' == 1 or vim.fn.executable 'make' == 0 then
          return
        end
        return 'make install_jsregexp'
      end)(),
      dependencies = {
        {
          'rafamadriz/friendly-snippets',
          config = function()
            require('luasnip.loaders.from_vscode').lazy_load()
            -- Personal snippets (same VSCode-JSON format as friendly-snippets), one file
            -- per filetype: lua/snippets/vscode/<filetype>.json. Add/edit with :SnippetNew
            -- / :SnippetEdit (see lua/snippet_editor.lua) — no Lua required.
            require('luasnip.loaders.from_vscode').lazy_load { paths = vim.fn.stdpath 'config' .. '/lua/snippets/vscode' }
            -- "Smart" snippets: treesitter/regex-driven, defined in
            -- lua/snippets/smart/<filetype>.json, built by lua/snippet_engine.lua.
            -- Same :SnippetNew/:SnippetList UI as plain snippets, see snippet_editor.lua.
            require('snippet_engine').load_all()
          end,
        },
      },
    },
    'saadparwaiz1/cmp_luasnip',
    'hrsh7th/cmp-nvim-lsp',
    'hrsh7th/cmp-path',
    'hrsh7th/cmp-buffer',
  },
  config = function()
    local cmp = require 'cmp'
    local luasnip = require 'luasnip'
    -- loaders_store_source: records which file each snippet came from (snip._source.file).
    -- Used by snippet_editor.lua to tell "our personal override" apart from
    -- "friendly-snippets' original" when reapplying exclusions after a restart.
    luasnip.config.setup { loaders_store_source = true }
    luasnip.filetype_extend('typescriptreact', { 'typescript' })
    luasnip.filetype_extend('javascriptreact', { 'javascript' })

    cmp.setup {
      snippet = {
        expand = function(args)
          luasnip.lsp_expand(args.body)
        end,
      },
      completion = { completeopt = 'menu,menuone,noinsert' },
      formatting = {
        format = function(_, item)
          local max = 60
          if vim.fn.strdisplaywidth(item.abbr) > max then
            item.abbr = vim.fn.strcharpart(item.abbr, 0, max - 1) .. '…'
          end
          return item
        end,
      },
      mapping = cmp.mapping.preset.insert {
        ['<C-b>'] = cmp.mapping.scroll_docs(-4),
        ['<C-f>'] = cmp.mapping.scroll_docs(4),
        ['<C-y>'] = cmp.mapping.confirm { select = true },
        ['<CR>'] = cmp.mapping.confirm { select = true },
        ['<Tab>'] = cmp.mapping.select_next_item(),
        ['<S-Tab>'] = cmp.mapping.select_prev_item(),
        ['<C-Space>'] = cmp.mapping.complete {},
        ['<C-l>'] = cmp.mapping(function()
          if luasnip.expand_or_locally_jumpable() then
            luasnip.expand_or_jump()
          end
        end, { 'i', 's' }),
        ['<C-h>'] = cmp.mapping(function()
          if luasnip.locally_jumpable(-1) then
            luasnip.jump(-1)
          end
        end, { 'i', 's' }),
      },
      sources = {
        { name = 'nvim_lsp' },
        { name = 'luasnip' },
        { name = 'path' },
        { name = 'buffer', keyword_length = 3 },
      },
    }
  end,
}
