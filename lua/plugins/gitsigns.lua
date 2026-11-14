-- Git change markers in the sign column. Blame and lazygit come from snacks.
---@module 'lazy'
---@type LazySpec
return {
  {
    'lewis6991/gitsigns.nvim',
    opts = {
      signs = {
        add = { text = '+' },
        change = { text = '~' },
        delete = { text = '_' },
        topdelete = { text = '‾' },
        changedelete = { text = '~' },
      },
    },
  },
}

-- vim: ts=2 sts=2 sw=2 et
