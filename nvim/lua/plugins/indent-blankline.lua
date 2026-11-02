-- indent-blankline.nvim: vertical indentation guide lines, including on
-- blank lines.
-- https://github.com/lukas-reineke/indent-blankline.nvim
--
-- Commented out while trying snacks.indent instead (see plugins/snacks.lua)
-- -- same core feature (guides + current-scope highlight), plus animation,
-- one less dependency.
return {
  {
    'lukas-reineke/indent-blankline.nvim',
    main = 'ibl',
    ---@module "ibl"
    ---@type ibl.config
    opts = {},
  },
}
-- return {}
