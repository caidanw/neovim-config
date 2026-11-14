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
      -- Set up snacks toggle keymap for rendering markdown
      require('snacks').toggle
        .new({
          name = 'Markdown Render',
          get = require('render-markdown').get,
          set = require('render-markdown').set,
        })
        :map('<leader>um')
      require('render-markdown').set(false)
    end,
  },
}
