-- Built-in LSP setup: keymaps, diagnostics and progress.
-- Server configs live in ../../lsp/*.lua; mason-lspconfig enables the servers mason installed.

local function source_action()
  vim.lsp.buf.code_action({ context = { only = { 'source' }, diagnostics = {} } })
end

local function organize_imports()
  vim.lsp.buf.code_action({ context = { only = { 'source.organizeImports' }, diagnostics = {} }, apply = true })
end

local function toggle_codelens()
  vim.lsp.codelens.enable(not vim.lsp.codelens.is_enabled({ bufnr = 0 }), { bufnr = 0 })
end

vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('config.lsp_attach', { clear = true }),
  callback = function(event)
    local function map(keys, func, desc, mode)
      vim.keymap.set(mode or 'n', keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
    end

    map('<leader>cr', vim.lsp.buf.rename, 'Rename')
    map('<leader>ca', vim.lsp.buf.code_action, 'Code Action', { 'n', 'v' })
    map('<leader>cA', source_action, 'Source Action')
    map('<leader>cc', vim.lsp.codelens.run, 'Run Codelens')
    map('<leader>cC', toggle_codelens, 'Toggle Codelens')
    map('<leader>co', organize_imports, 'Organize Imports')
    map('<leader>cd', vim.diagnostic.open_float, 'Show Diagnostics')

    -- Built-in defaults kept as is: grn rename, gra code action, grx run codelens,
    -- K hover, <C-s> signature help. These override the built-in list/quickfix
    -- versions with snacks pickers, on the same keys.
    map('grr', Snacks.picker.lsp_references, 'References')
    map('gri', Snacks.picker.lsp_implementations, 'Implementations')
    map('grt', Snacks.picker.lsp_type_definitions, 'Type Definitions')
    map('gO', Snacks.picker.lsp_symbols, 'Document Symbols')
    map('gW', Snacks.picker.lsp_workspace_symbols, 'Workspace Symbols')
    map('gd', Snacks.picker.lsp_definitions, 'Goto Definition')
    map('gD', Snacks.picker.lsp_declarations, 'Goto Declaration')

    -- Editing an HTML/JSX tag name also renames its closing tag, where the server supports it.
    local client = vim.lsp.get_client_by_id(event.data.client_id)
    if client and client:supports_method('textDocument/linkedEditingRange') then
      vim.lsp.linked_editing_range.enable(true, { client_id = client.id })
    end
  end,
})

vim.diagnostic.config({
  severity_sort = true,
  float = { border = 'rounded', source = 'if_many' },
  underline = { severity = vim.diagnostic.severity.ERROR },
  signs = vim.g.have_nerd_font and {
    text = {
      [vim.diagnostic.severity.ERROR] = '󰅚 ',
      [vim.diagnostic.severity.WARN] = '󰀪 ',
      [vim.diagnostic.severity.INFO] = '󰋽 ',
      [vim.diagnostic.severity.HINT] = '󰌶 ',
    },
  } or {},
  virtual_lines = { current_line = true },
})

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

-- Astro and other Volar-based servers send edits stamped with stale document
-- versions, which Nvim rejects ("buffer newer than edits"). Drop the version
-- check for those servers only. https://github.com/neovim/neovim/issues/12970
local stale_edit_servers = { 'astro', 'vue_ls', 'volar' }
local apply_text_document_edit = vim.lsp.util.apply_text_document_edit
---@diagnostic disable-next-line: duplicate-set-field
vim.lsp.util.apply_text_document_edit = function(text_document_edit, index, position_encoding, ...)
  local text_document = text_document_edit.textDocument
  local bufnr = vim.uri_to_bufnr(text_document.uri)
  for _, client in ipairs(vim.lsp.get_clients({ bufnr = bufnr })) do
    if vim.tbl_contains(stale_edit_servers, client.name) then
      text_document.version = nil
      break
    end
  end
  return apply_text_document_edit(text_document_edit, index, position_encoding, ...)
end

-- sourcekit-lsp ships with Xcode rather than mason, so enable it explicitly.
if vim.fn.executable('sourcekit-lsp') == 1 then
  vim.lsp.enable('sourcekit')
end

-- vim: ts=2 sts=2 sw=2 et
