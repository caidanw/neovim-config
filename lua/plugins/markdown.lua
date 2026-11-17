---@module 'lazy'
---@type LazySpec
return {
  {
    'MeanderingProgrammer/render-markdown.nvim',
    dependencies = { 'nvim-treesitter/nvim-treesitter' },
    ft = { 'markdown' },
    ---@module 'render-markdown'
    ---@type render.md.UserConfig
    opts = {},
    init = function()
      -- <leader>um toggles rendering, which is on by default.
      require('snacks').toggle
        .new({
          name = 'Markdown Render',
          get = require('render-markdown').get,
          set = require('render-markdown').set,
        })
        :map('<leader>um')
    end,
  },
}
