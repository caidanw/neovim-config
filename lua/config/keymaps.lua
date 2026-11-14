-- General keymaps. LSP keymaps are in config/lsp.lua; plugin keymaps live in their specs.
local map = vim.keymap.set

map('n', '<Esc>', '<cmd>nohlsearch<CR>', { desc = 'Clear search highlight' })
map('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Diagnostics to location list' })
map('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

-- Windows
map('n', '<C-h>', '<C-w><C-h>', { desc = 'Move focus to the left window' })
map('n', '<C-l>', '<C-w><C-l>', { desc = 'Move focus to the right window' })
map('n', '<C-j>', '<C-w><C-j>', { desc = 'Move focus to the lower window' })
map('n', '<C-k>', '<C-w><C-k>', { desc = 'Move focus to the upper window' })
map('n', '<leader>-', '<C-W>s', { desc = 'Split Window Below', remap = true })
map('n', '<leader>|', '<C-W>v', { desc = 'Split Window Right', remap = true })
map('n', '<leader>wd', '<C-W>c', { desc = 'Delete Window', remap = true })

-- Move by display line unless a count is given, so `5j` still counts real lines.
map({ 'n', 'x' }, 'j', "v:count == 0 ? 'gj' : 'j'", { desc = 'Down', expr = true, silent = true })
map({ 'n', 'x' }, 'k', "v:count == 0 ? 'gk' : 'k'", { desc = 'Up', expr = true, silent = true })

-- Buffers and files
map('n', '<leader>bb', '<cmd>e #<cr>', { desc = 'Switch to Other Buffer' })
map('n', '<leader>fn', '<cmd>enew<cr>', { desc = 'New File' })

-- Move lines
map('n', '<A-j>', "<cmd>execute 'move .+' . v:count1<cr>==", { desc = 'Move Down' })
map('n', '<A-k>', "<cmd>execute 'move .-' . (v:count1 + 1)<cr>==", { desc = 'Move Up' })
map('i', '<A-j>', '<esc><cmd>m .+1<cr>==gi', { desc = 'Move Down' })
map('i', '<A-k>', '<esc><cmd>m .-2<cr>==gi', { desc = 'Move Up' })
map('v', '<A-j>', ":<C-u>execute \"'<,'>move '>+\" . v:count1<cr>gv=gv", { desc = 'Move Down' })
map('v', '<A-k>', ":<C-u>execute \"'<,'>move '<-\" . (v:count1 + 1)<cr>gv=gv", { desc = 'Move Up' })

-- Keep the selection after indenting
map('v', '<', '<gv', { desc = 'Indent left and keep selection' })
map('v', '>', '>gv', { desc = 'Indent right and keep selection' })

-- Run Lua
map('n', '<leader>cx', '<cmd>source %<CR>', { desc = 'Source current file' })
map('n', '<leader>cX', '<cmd>.lua<CR>', { desc = 'Execute current line as Lua' })
map('v', '<leader>cx', '<cmd>lua<CR>', { desc = 'Execute selection as Lua' })

map('n', '<leader>L', '<cmd>Lazy<CR>', { desc = 'Lazy' })
map('n', '<leader>zz', '<cmd>qa<cr>', { desc = 'Quit All' })

-- vim: ts=2 sts=2 sw=2 et
