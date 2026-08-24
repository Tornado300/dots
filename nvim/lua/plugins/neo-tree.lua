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
  opts = {
    filesystem = {
      window = {
        mappings = {
          ['t'] = 'close_window',
        },
      },
      filtered_items = {
        visible = true,
        hide_dotfiles = false,
        hide_gitignored = false,
      },
    },
  },
}
