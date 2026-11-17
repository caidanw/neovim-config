-- Leader keys must be set before lazy.nvim loads plugins, so mappings use the right leader.
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- Set to false if the terminal font is not a Nerd Font.
vim.g.have_nerd_font = true

-- Settings: apply as soon as they are required.
require('config.options')
require('config.keymaps')
require('config.autocmds')
require('config.lsp')
require('config.completion')

-- Features: do nothing until set up.
require('features.progress').setup()
require('features.session').setup()
require('features.lsp_suggest').setup()
require('features.macro_recording').setup()

-- Plugins, from lua/plugins/.
require('config.lazy')

-- vim: ts=2 sts=2 sw=2 et
