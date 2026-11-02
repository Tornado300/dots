-- dial.nvim: smarter increment/decrement (<leader>k / <leader>j) — numbers,
-- dates, booleans, and/or, &&/||, semver, single letters, all cycle in
-- place. <leader>K / <leader>J do the sequential variant in visual mode
-- (1st match +1, 2nd +2, ...), e.g. for a, b, c, d or 10, 11, 12, 13.
-- https://github.com/monaqa/dial.nvim
return {
  'monaqa/dial.nvim',
  keys = {
    { '<leader>k', function() require('dial.map').manipulate('increment', 'normal') end, mode = 'n', desc = 'Increment' },
    { '<leader>j', function() require('dial.map').manipulate('decrement', 'normal') end, mode = 'n', desc = 'Decrement' },
    { '<leader>k', function() require('dial.map').manipulate('increment', 'visual') end, mode = 'v', desc = 'Increment' },
    { '<leader>j', function() require('dial.map').manipulate('decrement', 'visual') end, mode = 'v', desc = 'Decrement' },
    -- Sequential: 1st match +1, 2nd +2, 3rd +3, ... (like native g<C-a>/g<C-x>)
    -- instead of the same amount everywhere -- e.g. select a column of "a"s
    -- with the alpha augend below and get a, b, c, d, e...
    { '<leader>K', function() require('dial.map').manipulate('increment', 'gvisual') end, mode = 'v', desc = 'Increment (sequential)' },
    { '<leader>J', function() require('dial.map').manipulate('decrement', 'gvisual') end, mode = 'v', desc = 'Decrement (sequential)' },
  },
  config = function()
    local augend = require 'dial.augend'
    require('dial.config').augends:register_group {
      default = {
        augend.integer.alias.decimal,
        augend.integer.alias.hex,
        augend.date.alias['%Y-%m-%d'],
        augend.date.alias['%Y/%m/%d'],
        augend.constant.alias.bool, -- true/false
        augend.constant.alias.Bool, -- True/False (Python, etc.)
        augend.constant.alias.alpha, -- a, b, c, ... z (single lowercase letter)
        augend.constant.alias.Alpha, -- A, B, C, ... Z (single uppercase letter)
        augend.constant.new { elements = { 'and', 'or' }, word = true, cyclic = true },
        augend.constant.new { elements = { '&&', '||' }, word = false, cyclic = true },
        augend.semver.alias.semver,
      },
    }
  end,
}
