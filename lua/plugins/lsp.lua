-- Language servers: nvim-lspconfig supplies default server configs (its lsp/
-- directory), ../../lsp/*.lua extends them, and mason installs the binaries.
-- Keymaps and diagnostics are in lua/config/lsp.lua.

---@module 'lazy'
---@type LazySpec
return {
  {
    'neovim/nvim-lspconfig',
  },
  {
    'mason-org/mason.nvim',
    opts = {},
  },
  {
    -- Calls vim.lsp.enable() for every server mason has installed.
    'mason-org/mason-lspconfig.nvim',
    dependencies = { 'mason-org/mason.nvim', 'neovim/nvim-lspconfig' },
    opts = {
      automatic_enable = {
        -- conform runs the stylua CLI on save; its LSP mode adds nothing.
        exclude = { 'stylua' },
      },
    },
  },
  {
    -- Installs missing tools on startup. Language servers come from
    -- lsp-servers.json (lspconfig names), which :LspSuggest adds to.
    'WhoIsSethDaniel/mason-tool-installer.nvim',
    dependencies = { 'mason-org/mason.nvim', 'mason-org/mason-lspconfig.nvim' },
    opts = function()
      local servers = require('config.lsp_suggest.store').servers()
      -- Formatters conform runs on save. ruff also runs as a Python language server.
      return { ensure_installed = vim.list_extend(servers, { 'prettier', 'ruff', 'stylua' }) }
    end,
  },
  {
    -- JSON and YAML schemas, loaded by lsp/jsonls.lua and lsp/yamlls.lua.
    'b0o/schemastore.nvim',
    lazy = true,
    version = false, -- the last tagged release is very old
  },
  {
    -- Types for the Neovim API, plugins and libuv when editing Lua in this config.
    'folke/lazydev.nvim',
    ft = 'lua',
    opts = {
      library = {
        { path = '${3rd}/luv/library', words = { 'vim%.uv' } },
        { path = 'snacks.nvim', words = { 'Snacks' } },
        { path = 'lazy.nvim' },
      },
    },
  },
}

-- vim: ts=2 sts=2 sw=2 et
