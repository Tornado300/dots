-- nvim-treesitter-context: pins the enclosing function/block header to the
-- top of the window while you scroll past it.
-- https://github.com/nvim-treesitter/nvim-treesitter-context
return {
  "nvim-treesitter/nvim-treesitter-context",
  config = function()
    require("treesitter-context").setup({
      enable = true,
      max_lines = 5,       -- how many lines of context to show
      line_numbers = false,
      trim_scope = "outer", -- shows outer scope if needed
      mode = "topline",      -- context updates based on cursor
    })
  end
}
