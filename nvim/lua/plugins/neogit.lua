-- Neogit: Magit-style git porcelain — status, staging, committing, push/pull.
-- https://github.com/NeogitOrg/neogit
return {
  'NeogitOrg/neogit',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'sindrets/diffview.nvim',
  },
  opts = {
    commit_editor = { kind = 'floating' },
  },
}
