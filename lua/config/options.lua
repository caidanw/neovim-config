-- Editor options. See `:help option-list`.

vim.o.number = true
vim.o.relativenumber = true
vim.o.cursorline = false
vim.o.scrolloff = 7
vim.o.wrap = true
vim.o.virtualedit = 'block' -- In block selections, allow the cursor past the end of a line.

-- Indent with tabs, 4 columns wide. editorconfig and formatters override this per project.
vim.o.expandtab = false
vim.o.shiftwidth = 4
vim.o.tabstop = 4
vim.o.smarttab = true
vim.o.shiftround = true

vim.o.mouse = 'a'
vim.o.showmode = false -- The statusline shows the mode.

vim.o.breakindent = true
vim.o.undofile = true

-- Searches ignore case unless they contain a capital letter or \C.
vim.o.ignorecase = true
vim.o.smartcase = true

vim.o.inccommand = 'split' -- Preview :substitute in a split as you type.
vim.o.signcolumn = 'yes'
vim.o.foldcolumn = 'auto'

vim.o.updatetime = 250
vim.o.timeoutlen = 300

vim.o.splitright = true
vim.o.splitbelow = true

vim.o.winborder = 'rounded'
vim.o.winblend = 0
vim.o.pumblend = 0

vim.o.sessionoptions = 'buffers,curdir,folds,help,tabpages,winsize,terminal'

-- Share the system clipboard. Set after startup because the clipboard
-- provider can slow startup down.
vim.schedule(function()
  vim.o.clipboard = 'unnamedplus'
end)

vim.o.list = true
vim.opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' }

-- Ask to save instead of failing when quitting with unsaved changes.
vim.o.confirm = true

-- Macro recording (`q`) starts disabled; toggle it with <leader>uq.
vim.g.macro_recording = false

-- vim: ts=2 sts=2 sw=2 et
