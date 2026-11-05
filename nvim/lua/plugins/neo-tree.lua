-- Neo-tree: file tree sidebar. Toggled via <M-h> (see keybinds.lua), which
-- reveals/focuses/closes the tree — that's the only entry point; a global
-- `t` keymap used to also reveal it here, clobbering vim's built-in
-- `t{char}` till-motion everywhere, and has been removed.
-- https://github.com/nvim-neo-tree/neo-tree.nvim

return {
  'nvim-neo-tree/neo-tree.nvim',
  version = '*',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'nvim-tree/nvim-web-devicons', -- not strictly required, but recommended
    'MunifTanjim/nui.nvim',
  },
  cmd = 'Neotree',
  -- opts as a function, not a plain table: it's evaluated once the plugin is
  -- actually loaded (neo-tree is cmd-triggered, so lazy), whereas a plain
  -- table's require('neo-tree.events') below would run at spec-definition
  -- time, before neo-tree.nvim is even on the runtimepath.
  opts = function()
    -- When a file is moved (x cut + p paste, or renamed with r), tell any
    -- attached LSP so it can fix up import paths referencing the old
    -- location.
    local events = require 'neo-tree.events'
    local on_move = function(data) Snacks.rename.on_rename_file(data.source, data.destination) end
    return {
      event_handlers = {
        { event = events.FILE_MOVED, handler = on_move },
        { event = events.FILE_RENAMED, handler = on_move },
      },
      filesystem = {
        window = {
          mappings = {
            ['t'] = 'close_window',
          },
        },
        filtered_items = {
          visible = false, -- actually hide these, not just dim them
          hide_dotfiles = false, -- still show .env, .gitignore itself, etc.
          hide_gitignored = true, -- catches .venv/__pycache__ etc. when they're in .gitignore, as usual
          -- belt-and-suspenders: hidden even if a project's .gitignore doesn't
          -- happen to list these (e.g. a global gitignore handles it instead).
          hide_by_name = { '.venv', '__pycache__', '.git' },
        },
      },
    }
  end,
}
