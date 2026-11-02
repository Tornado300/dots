-- snacks.nvim: multi-feature QoL bundle. Enabled here: dashboard (<leader>m),
-- picker (fuzzy find/grep/etc, see <leader>s*), notifier (<leader>n),
-- toggle helpers, big-file handling, animated scroll, and indent guides.
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
    -- Trying this in place of indent-blankline.nvim (commented out, see
    -- plugins/indent-blankline.lua): same guides + current-scope highlight,
    -- plus animation on by default, one less dependency if it sticks.
    indent = {
      enabled = true,
      -- No animation: snap straight to the new scope highlight instead of
      -- transitioning, so there's nothing to overlap/flicker on fast moves.
      animate = { enabled = false },
      scope = {
        -- Default debounce (30ms) recalculates on nearly every cursor move,
        -- so scrolling through nested code flickers through each level on
        -- the way. Raised so the highlight only updates once the cursor's
        -- actually settled somewhere, not while passing through.
        debounce = 45,
        treesitter = {
          -- Without this, scope falls back to "nearest node with a
          -- different indent" -- i.e. every if/for/nested block counts,
          -- which is what was actually causing most of the flicker (a new
          -- scope boundary on nearly every line of normal code). Restricted
          -- to function/class, matching what ibl showed by default (its
          -- python scope list is module/class_definition/function_definition,
          -- deliberately excluding if/for/while).
          blocks = {
            enabled = true,
            'function_declaration',
            'function_definition',
            'method_declaration',
            'method_definition',
            'class_declaration',
            'class_definition',
            'arrow_function', -- JS/TS: () => {}
            'function_expression', -- JS/TS: const x = function() {}
          },
        },
      },
    },
    -- Animation is opt-in per-buffer only (see the animated_scroll() wrapper
    -- in keybinds.lua for C-d/C-u/C-f/C-b) rather than applying to every
    -- jump/scroll: an "on by default, exclude gg/G" filter can't reliably
    -- catch every way gg/G get invoked (e.g. remapped/noremap'd sequences),
    -- and mid-animation input (e.g. immediate y after a jump) desyncs from
    -- the animation's intermediate cursor position.
    scroll = {
      enabled = true,
      animate = { duration = { step = 8, total = 120 }, easing = 'linear' },
      animate_repeat = { delay = 100, duration = { step = 4, total = 30 }, easing = 'linear' },
      filter = function(buf)
        return vim.b[buf].snacks_scroll == true
      end,
    },
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
    input = { enabled = true },
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
