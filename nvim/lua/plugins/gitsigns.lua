-- Gitsigns: sign-column glyphs for hunks, plus in-buffer hunk navigation/
-- preview/blame. Staging & committing are handled by Neogit, not here.
-- https://github.com/lewis6991/gitsigns.nvim
return {
  'lewis6991/gitsigns.nvim',
  opts = {
    signs = {
      add = { text = '+' },
      change = { text = '~' },
      delete = { text = '_' },
      topdelete = { text = '‾' },
      changedelete = { text = '~' },
    },
    on_attach = function(bufnr)
      local gitsigns = require 'gitsigns'

      local function map(mode, l, r, opts)
        opts = opts or {}
        opts.buffer = bufnr
        vim.keymap.set(mode, l, r, opts)
      end

      -- Navigation (leader-based, not ]c/[c — those sit behind AltGr on German keyboards)
      map('n', '<leader>hn', function()
        if vim.wo.diff then
          vim.cmd.normal { ']c', bang = true }
        else
          gitsigns.nav_hunk 'next'
        end
      end, { desc = 'Jump to next git hu[n]k' })

      map('n', '<leader>hN', function()
        if vim.wo.diff then
          vim.cmd.normal { '[c', bang = true }
        else
          gitsigns.nav_hunk 'prev'
        end
      end, { desc = 'Jump to previous git hu[n]k' })

      -- Closes the gitsigns diff split(s) opened by <leader>hd/<leader>hD. gitsigns.diffthis()
      -- no-ops if already in diff mode (no built-in toggle-off), so do it ourselves: closing
      -- the gitsigns:// scratch window triggers gitsigns' own BufHidden handler, which clears
      -- 'diff' on the original window too.
      local function close_gitsigns_diff()
        for _, win in ipairs(vim.api.nvim_list_wins()) do
          local buf = vim.api.nvim_win_get_buf(win)
          if vim.api.nvim_buf_get_name(buf):match '^gitsigns://' then
            vim.api.nvim_win_close(win, false)
          end
        end
      end

      -- Inspect
      map('n', '<leader>hp', gitsigns.preview_hunk, { desc = 'git [p]review hunk' })
      map('n', '<leader>hb', gitsigns.blame_line, { desc = 'git [b]lame line' })
      map('n', '<leader>hd', function()
        if vim.wo.diff then
          close_gitsigns_diff()
        else
          gitsigns.diffthis()
        end
      end, { desc = 'git [d]iff against index (toggle)' })
      map('n', '<leader>hD', function()
        if vim.wo.diff then
          close_gitsigns_diff()
        else
          gitsigns.diffthis '@'
        end
      end, { desc = 'git [D]iff against last commit (toggle)' })

      -- Toggles
      map('n', '<leader>tb', gitsigns.toggle_current_line_blame, { desc = '[T]oggle git show [b]lame line' })
      map('n', '<leader>tD', gitsigns.toggle_deleted, { desc = '[T]oggle git show [D]eleted' })
    end,
  },
}
