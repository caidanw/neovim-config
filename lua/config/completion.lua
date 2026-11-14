-- Built-in insert-mode completion. See `:help ins-autocompletion` and `:help lsp-completion`.
--
-- The menu opens as you type. Items come from the language server (via
-- 'omnifunc'), then words from the current buffer, other windows and listed
-- buffers. <C-n>/<C-p> move, <C-y> accepts, <C-e> closes, <C-space> asks the
-- language server directly. In insert mode, <C-s> shows signature help.

vim.o.autocomplete = true
vim.o.complete = 'o,.,w,b'
vim.o.completeopt = 'menuone,noselect,popup,fuzzy'
vim.o.pumborder = 'rounded'

-- Accept the first item when none is selected. With 'autocomplete' nothing is
-- preselected, so plain <C-y> would do nothing.
vim.keymap.set('i', '<C-y>', function()
  if vim.fn.pumvisible() == 1 and vim.fn.complete_info({ 'selected' }).selected == -1 then
    return '<C-n><C-y>'
  end
  return '<C-y>'
end, { expr = true, desc = 'Accept completion' })

vim.keymap.set('i', '<C-space>', vim.lsp.completion.get, { desc = 'LSP completion' })

local group = vim.api.nvim_create_augroup('config.completion', { clear = true })

-- Enabling LSP completion makes accepted items apply their side effects:
-- auto-imports, snippet expansion and follow-up commands.
vim.api.nvim_create_autocmd('LspAttach', {
  group = group,
  callback = function(ev)
    local client = vim.lsp.get_client_by_id(ev.data.client_id)
    if client and client:supports_method('textDocument/completion') then
      vim.lsp.completion.enable(true, client.id, ev.buf)
    end
  end,
})

-- Only complete in normal file buffers, not in pickers, prompts or oil.
vim.api.nvim_create_autocmd('InsertEnter', {
  group = group,
  callback = function(ev)
    if vim.bo[ev.buf].buftype ~= '' then
      vim.bo[ev.buf].autocomplete = false
    end
  end,
})

-- vim: ts=2 sts=2 sw=2 et
