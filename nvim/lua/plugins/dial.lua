-- dial.nvim: smarter increment/decrement (<leader>k / <leader>j) — numbers,
-- dates, booleans, and/or, &&/||, semver, all cycle in place.
-- https://github.com/monaqa/dial.nvim
return {
  'monaqa/dial.nvim',
  keys = {
    { '<leader>k', function() require('dial.map').manipulate('increment', 'normal') end, mode = 'n', desc = 'Increment' },
    { '<leader>j', function() require('dial.map').manipulate('decrement', 'normal') end, mode = 'n', desc = 'Decrement' },
    { '<leader>k', function() require('dial.map').manipulate('increment', 'visual') end, mode = 'v', desc = 'Increment' },
    { '<leader>j', function() require('dial.map').manipulate('decrement', 'visual') end, mode = 'v', desc = 'Decrement' },
  },
  config = function()
    local augend = require 'dial.augend'
    require('dial.config').augends:register_group {
      default = {
        augend.integer.alias.decimal,
        augend.integer.alias.hex,
        augend.date.alias['%Y-%m-%d'],
        augend.date.alias['%Y/%m/%d'],
        augend.constant.alias.bool,
        augend.constant.new { elements = { 'and', 'or' }, word = true, cyclic = true },
        augend.constant.new { elements = { '&&', '||' }, word = false, cyclic = true },
        augend.semver.alias.semver,
      },
    }
  end,
}
