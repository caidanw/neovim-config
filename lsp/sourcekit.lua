---Docs: https://www.swift.org/documentation/articles/zero-to-swift-nvim.html
---@type vim.lsp.Config
return {
  cmd = { 'sourcekit-lsp' },
  filetypes = { 'swift' },
  root_markers = {
    'Package.swift',
    'compile_commands.json',
    '.sourcekit-lsp',
    '.git',
  },
  capabilities = {
    workspace = {
      didChangeWatchedFiles = {
        dynamicRegistration = true,
      },
    },
    textDocument = {
      diagnostic = {
        dynamicRegistration = true,
        relatedDocumentSupport = true,
      },
    },
  },
}
