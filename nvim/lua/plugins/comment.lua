-- Comment.nvim: toggle line comments with <leader>c. Block-comment support
-- was removed -- rarely a win over // for a single line, and the
-- motion/visual-range case is covered by selecting and using <leader>c.
-- NOTE: Comment.nvim always creates its own hardcoded gb/gbc block-comment
-- keys from mappings.basic, independent of toggler/opleader.block (which we
-- just omit here) -- there's no config option to suppress only those, so
-- they're explicitly <Nop>'d in keybinds.lua instead.
-- https://github.com/numToStr/Comment.nvim
return {
  'numToStr/Comment.nvim',
  opts = {
    toggler = { line = '<leader>c' },
    opleader = { line = '<leader>c' },
    mappings = { extra = false },
  },
}
