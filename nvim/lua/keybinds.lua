-- #### CUSTOM FUNCTIONS #### --
function ToggleComment()
    local line = vim.api.nvim_get_current_line()  -- Get the current line
    local indentation = line:match("^%s*")  -- Capture the leading whitespace (indentation)
    if line:match("^%s*#") then
        -- Uncomment the line if it starts with #
        line = line:gsub("^%s*# ", indentation, 1)
    else
        -- Add # after the indentation
        line = indentation .. "# " .. line:sub(#indentation + 1)
    end
    vim.api.nvim_set_current_line(line)  -- Update the current line
end


-- ####STANDART KEYBINDS#### --

-- Esc to remove search highlight
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')
-- open error message
vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float, { desc = 'Show diagnostic [E]rror messages' })
-- Escape the terminal mode with double Esc
vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })
--  Use CTRL+<hjkl> to switch between windows
--  See `:help wincmd` for a list of all window commands
vim.keymap.set('n', '<C-h>', '<C-w><C-h>', { desc = 'Move focus to the left window' })
vim.keymap.set('n', '<C-l>', '<C-w><C-l>', { desc = 'Move focus to the right window' })
vim.keymap.set('n', '<C-j>', '<C-w><C-j>', { desc = 'Move focus to the lower window' })
vim.keymap.set('n', '<C-k>', '<C-w><C-k>', { desc = 'Move focus to the upper window' })



-- ####CUSTOM KEYBINDS#### --

-- toggle relative line numbers
Snacks.toggle.new({name = "Toggle relative line Numbers", 
                   get = function() return vim.wo.relativenumber end, 
                   set = function(state) if state then vim.wo.relativenumber = false else vim.wo.relativenumber = true end end}, 
                   opts
                  ):map("<leader>tl")


-- toggle terminal
vim.keymap.set("n", "T", "<cmd>ToggleTerm<CR>")
-- activate venv and execute (depending on file type)
vim.keymap.set("n", "<C-e>p",":TermExec cmd='cd %:p:h'<CR>:TermExec cmd='source ./.venv/bin/activate'<CR> :TermExec cmd='python %:t' go_back=0<CR>", {desc="execute python file"})
-- open main menu
vim.api.nvim_set_keymap('n', '<leader>m', [[:lua Snacks.dashboard.open()<CR>]], { desc="Open Main Menu", noremap = true, silent = true })
-- select whole file
vim.api.nvim_set_keymap("v", "A", "<Esc>gg0vG$", { desc="select whole file", noremap = true, silent = true })
-- comment/uncomment current line
-- vim.api.nvim_set_keymap('n', '<leader>c', [[:lua ToggleComment()<CR>]], { desc="toggle comment on current line", noremap = true, silent = true })
