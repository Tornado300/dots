-- d2-vim: filetype support for D2 diagram scripts, plus buffer-local
-- insert-mode shortcuts for common arrow/edge syntax.
-- https://github.com/terrastruct/d2-vim
return {
  'terrastruct/d2-vim',
  ft = 'd2',
  init = function()
    vim.g.d2_fmt_autosave = 0
    vim.g.d2_validate_autosave = 0
  end,
  config = function()
    vim.api.nvim_create_autocmd('FileType', {
      pattern = 'd2',
      callback = function(ev)
        local function map(lhs, rhs, desc)
          vim.keymap.set('i', lhs, rhs, { buffer = ev.buf, desc = desc })
        end
        map(',a', '-> ', 'D2: insert ->')
        map(',d', '<-> ', 'D2: insert <->')
        map(',b', '<- ', 'D2: insert <-')
        map(',l', '-- ', 'D2: insert --')
        map(',c', ': {<CR>}<Esc>O', 'D2: insert block { }')
      end,
    })
  end,
}
