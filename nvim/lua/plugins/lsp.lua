-- nvim-lspconfig + mason: language server management and per-language LSP
-- config (diagnostics, hover, rename, code actions, inlay hints). This is
-- where every configured language server lives.
-- https://github.com/neovim/nvim-lspconfig
return {
  'neovim/nvim-lspconfig',
  dependencies = {
    { 'williamboman/mason.nvim', config = true },
    'williamboman/mason-lspconfig.nvim',
    'WhoIsSethDaniel/mason-tool-installer.nvim',
    { 'j-hui/fidget.nvim', opts = {} },
    { 'folke/neodev.nvim', opts = {} },
  },
  config = function()
    require('mason').setup()
    require('mason-lspconfig').setup { automatic_enable = false }
    require('mason-tool-installer').setup {
      ensure_installed = {
        'html-lsp',
        'css-lsp',
        'typescript-language-server',
        'eslint-lsp',
        'prettier',
        'typos-lsp',
        'lua-language-server',
        'pyright',
        'ruff',
        'qmlls',
        'gopls',
        'spyglassmc-language-server',
        'json-lsp',
        'stylua',
        'bash-language-server',
        'markdownlint-cli2',
      },
    }

    vim.api.nvim_create_autocmd('LspAttach', {
      group = vim.api.nvim_create_augroup('kickstart-lsp-attach', { clear = true }),
      callback = function(event)
        local client = vim.lsp.get_client_by_id(event.data.client_id)
        if not client then
          return
        end

        if client.server_capabilities.inlayHintProvider then
          vim.lsp.inlay_hint.enable(true, { bufnr = event.buf })
        end

        if client.server_capabilities.documentHighlightProvider then
          local highlight_augroup = vim.api.nvim_create_augroup('kickstart-lsp-highlight', { clear = false })
          vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
            buffer = event.buf,
            group = highlight_augroup,
            callback = vim.lsp.buf.document_highlight,
          })
          vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
            buffer = event.buf,
            group = highlight_augroup,
            callback = vim.lsp.buf.clear_references,
          })
          vim.api.nvim_create_autocmd('LspDetach', {
            group = vim.api.nvim_create_augroup('kickstart-lsp-detach', { clear = true }),
            callback = function(event2)
              vim.lsp.buf.clear_references()
              vim.api.nvim_clear_autocmds { group = 'kickstart-lsp-highlight', buffer = event2.buf }
            end,
          })
        end
      end,
    })

    vim.lsp.config('lua_ls', {
      settings = {
        Lua = {
          runtime = { version = 'LuaJIT' },
          workspace = { checkThirdParty = false },
        },
      },
    })

    vim.lsp.config('pyright', {
      before_init = function(_, config)
        local venv = vim.fn.getcwd() .. '/.venv'
        if vim.fn.isdirectory(venv) == 1 then
          config.settings.python.pythonPath = venv .. '/bin/python'
        end
      end,
      settings = {
        python = {
          analysis = {
            typeCheckingMode = 'basic',
            inlayHints = {
              variableTypes = true,
              functionReturnTypes = true,
              callArgumentNames = true,
              pytestParameters = true,
            },
          },
        },
      },
    })

    vim.lsp.config('spyglassmc_language_server', {
      -- mcdoc: spyglassmc's schema language for describing/type-hinting the
      -- datapack JSON formats (loot tables, advancements, recipes, ...).
      -- (root_markers already defaults to just 'pack.mcmeta' upstream — datapacks
      -- don't use git, so no '.git' fallback is added here.)
      filetypes = { 'mcfunction', 'mcdoc' },
      capabilities = vim.tbl_deep_extend('force', vim.lsp.protocol.make_client_capabilities(), {
        workspace = {
          didChangeWatchedFiles = {
            dynamicRegistration = true,
          },
        },
      }),
      on_attach = function(client, bufnr)
        -- vim-mcfunction already provides syntax highlighting for .mcfunction,
        -- so drop LSP semantic tokens there to avoid clashing. .mcdoc has no
        -- separate syntax plugin, so it relies on semantic tokens and keeps them.
        if vim.bo[bufnr].filetype == 'mcfunction' then
          vim.lsp.semantic_tokens.stop(bufnr, client.id)
        end
      end,
    })

    -- rust_analyzer, gopls, ts_ls, eslint: no vim.lsp.config() block needed — their
    -- lspconfig defaults ship a root_dir *function* (cargo workspace / go.mod+GOMODCACHE
    -- / monorepo lockfile+deno-aware / eslint-config-probing detection respectively),
    -- which always wins over root_markers, so a hand-written root_markers list here
    -- would just be dead code. cmd/filetypes also match the defaults exactly.

    -- qmlls: cmd/filetypes/root_markers all match the default except this extra marker.
    vim.lsp.config('qmlls', {
      root_markers = { '*.qmlproject' },
    })

    vim.lsp.config('html', {
      init_options = {
        provideFormatter = false,
      },
    })

    vim.lsp.config('cssls', {
      init_options = {
        provideFormatter = false,
      },
    })

    -- Code-aware spellchecker (catches typos in identifiers/strings/comments without
    -- flagging snake_case/kebab-case/acronyms the way vim's native 'spell' does).
    -- cmd/root_markers match the lspconfig default, no config block needed.

    vim.lsp.enable 'bashls'
    vim.lsp.enable 'lua_ls'
    vim.lsp.enable 'pyright'
    vim.lsp.enable 'ruff'
    vim.lsp.enable 'spyglassmc_language_server'
    vim.lsp.enable 'rust_analyzer'
    vim.lsp.enable 'qmlls'
    vim.lsp.enable 'gopls'
    vim.lsp.enable 'jsonls'
    vim.lsp.enable 'html'
    vim.lsp.enable 'cssls'
    vim.lsp.enable 'ts_ls'
    vim.lsp.enable 'eslint'
    vim.lsp.enable 'typos_lsp'
  end,
}
