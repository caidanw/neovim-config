-- Install lazy.nvim on first start. See `:help lazy.nvim.txt`.
local lazypath = vim.fn.stdpath('data') .. '/lazy/lazy.nvim'
if not vim.uv.fs_stat(lazypath) then
  local lazyrepo = 'https://github.com/folke/lazy.nvim.git'
  local out = vim.fn.system({ 'git', 'clone', '--filter=blob:none', '--branch=stable', lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    error('Error cloning lazy.nvim:\n' .. out)
  end
end
vim.opt.rtp:prepend(lazypath)

-- Every file in lua/plugins/ returns one or more plugin specs.
require('lazy').setup({ import = 'plugins' }, {
  rocks = { enabled = false },
  -- An empty table uses lazy.nvim's Nerd Font icons.
  ui = { icons = vim.g.have_nerd_font and {} or nil },
})

-- vim: ts=2 sts=2 sw=2 et
