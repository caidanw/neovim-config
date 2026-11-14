-- Built-in LSP setup that does not depend on any plugin.

-- Show LSP progress (indexing, loading workspace, ...) as progress messages.
-- The cmdline shows them, and so do terminals that support OSC 9;4 progress bars.
vim.api.nvim_create_autocmd('LspProgress', {
  group = vim.api.nvim_create_augroup('config.lsp_progress', { clear = true }),
  callback = function(ev)
    local value = ev.data.params.value
    vim.api.nvim_echo({ { value.message or 'done' } }, false, {
      id = 'lsp.' .. ev.data.params.token,
      kind = 'progress',
      source = 'vim.lsp',
      title = value.title,
      status = value.kind ~= 'end' and 'running' or 'success',
      percent = value.percentage,
    })
  end,
})

-- vim: ts=2 sts=2 sw=2 et
