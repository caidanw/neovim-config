-- Leader keys must be set before lazy.nvim loads plugins, so mappings use the right leader.
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- Set to false if the terminal font is not a Nerd Font.
vim.g.have_nerd_font = true

require('config.options')
require('config.keymaps')
require('config.autocmds')
require('config.lazy')

-- vim: ts=2 sts=2 sw=2 et
