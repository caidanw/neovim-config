---@module 'lazy'
---@type LazySpec
return {
  'stevearc/oil.nvim',
  ---@module 'oil'
  ---@type oil.SetupOpts
  opts = {
    -- Open directories (`nvim .`, `:e src/`) in oil instead of netrw.
    default_file_explorer = true,
    -- Send deleted files to the trash instead of permanently deleting them (:help oil-trash)
    delete_to_trash = true,
    -- Reload when files change on disk.
    watch_for_changes = true,

    keymaps = {
      ['q'] = { 'actions.close', mode = 'n' },
      ['<M-h>'] = { 'actions.toggle_hidden', mode = 'n' },
      ['Y'] = { 'actions.yank_entry', mode = 'n' },
      ['gd'] = {
        function()
          vim.g.oil_columns = not vim.g.oil_columns
          local columns = vim.g.oil_columns and { 'icon', 'permissions', 'size', 'mtime' } or { 'icon' }
          require('oil').set_columns(columns)
        end,
        desc = 'Toggle columns',
      },
    },
  },
  -- oil's docs advise against lazy-loading it.
  lazy = false,
  keys = {
    { '<leader>fo', '<CMD>Oil<CR>', mode = 'n', desc = 'Open Oil' },
  },
}
