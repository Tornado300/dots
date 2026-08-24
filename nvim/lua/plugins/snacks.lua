-- snacks.nvim: multi-feature QoL bundle. Enabled here: dashboard (<leader>m),
-- picker (fuzzy find/grep/etc, see <leader>s*), notifier (<leader>n),
-- toggle helpers, and big-file handling.
-- https://github.com/folke/snacks.nvim
return {
  'folke/snacks.nvim',
  priority = 1000,
  lazy = false,
  ---@type snacks.Config
  opts = {
    bigfile = { enabled = true },
    dashboard = {
      preset = {
        header = [[
                                                                      
                                                                    
      ████ ██████           █████      ██                     
     ███████████             █████                             
     █████████ ███████████████████ ███   ███████████   
    █████████  ███    █████████████ █████ ██████████████   
   █████████ ██████████ █████████ █████ █████ ████ █████   
 ███████████ ███    ███ █████████ █████ █████ ████ █████  
██████  █████████████████████ ████ █████ █████ ████ ██████ 
                                                                      
                                                                      ]],
      },
      sections = {
        { section = 'header', padding = { 0, 7 } },
        { section = 'keys', gap = 1, padding = { 4, 0 } },
        { icon = ' ', title = 'Recent Files', section = 'recent_files', gap = 0, indent = 2, padding = { 11, 0 } },
        { section = 'startup' },
      },
    },
    toggle = { enabled = true },
    picker = {
      enabled = true,
      ui_select = true,
      win = {
        input = {
          keys = {
            ['<C-j>'] = { 'list_down', mode = { 'i', 'n' } },
            ['<C-k>'] = { 'list_up', mode = { 'i', 'n' } },
          },
        },
      },
    },
    notifier = { enabled = true, timeout = 3000 },
    styles = { dashboard = { wo = { foldmethod = 'manual' } }, notification = { wo = { wrap = true } } }, -- Wrap notifications
  },
  init = function()
    vim.api.nvim_create_autocmd('User', {
      pattern = 'VeryLazy',
      callback = function()
        -- Setup some globals for debugging (lazy-loaded)
        _G.dd = function(...)
          Snacks.debug.inspect(...)
        end
        _G.bt = function()
          Snacks.debug.backtrace()
        end
        vim.print = _G.dd -- Override print to use snacks for `:=` command
      end,
    })
  end,
}
