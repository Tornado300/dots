-- Comment.nvim: toggle line/block comments with <leader>c / <leader>bc.
-- https://github.com/numToStr/Comment.nvim
return {
  'numToStr/Comment.nvim',
  opts = {
    toggler = { line = '<leader>c', block = '<leader>bc' },
    opleader = { line = '<leader>c', block = '<leader>bc' },
    mappings = { extra = false },
  },
}
