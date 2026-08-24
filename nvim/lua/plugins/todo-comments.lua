-- todo-comments.nvim: highlights TODO/FIXME/NOTE/etc comments (no gutter
-- signs, just highlighting). Also searchable via Snacks/Telescope pickers.
-- https://github.com/folke/todo-comments.nvim
return {
  'folke/todo-comments.nvim',
  event = 'VimEnter',
  dependencies = { 'nvim-lua/plenary.nvim' },
  opts = { signs = false },
}
