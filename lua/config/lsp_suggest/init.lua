-- Offer to install a language server when you open a file type that has none.
--
-- After a file opens, if no enabled server handles its file type, this shows a
-- notification (or a picker, with `prompt = 'picker'`). :LspSuggest opens the
-- picker for the current file type at any time, even one you declined.
-- Picking a server installs it with mason, adds it to lsp-servers.json and
-- starts it in open buffers.

local servers = require('config.lsp_suggest.servers')
local store = require('config.lsp_suggest.store')

local M = {}

---@class lsp_suggest.Config
local defaults = {
  ---@type 'notify'|'picker'
  prompt = 'notify',
  -- ms to wait after a file opens, so servers that are starting can attach first
  delay = 1500,
  -- how many servers the first picker lists before "Show all"
  shown = 5,
  -- servers covering more file types than this count as general-purpose tools
  -- (spell checkers, linters, emmet) and are listed after language servers
  max_filetypes = 6,
  -- file type -> lspconfig name, listed first and marked "recommended"
  recommended = {
    astro = 'astro',
    bash = 'bashls',
    c = 'clangd',
    cpp = 'clangd',
    css = 'cssls',
    dockerfile = 'dockerls',
    elixir = 'elixirls',
    go = 'gopls',
    graphql = 'graphql',
    html = 'html',
    java = 'jdtls',
    javascript = 'vtsls',
    javascriptreact = 'vtsls',
    json = 'jsonls',
    kotlin = 'kotlin_language_server',
    lua = 'lua_ls',
    markdown = 'marksman',
    nix = 'nil_ls',
    php = 'intelephense',
    python = 'basedpyright',
    ruby = 'ruby_lsp',
    rust = 'rust_analyzer',
    sh = 'bashls',
    sql = 'sqls',
    svelte = 'svelte',
    terraform = 'terraformls',
    tex = 'texlab',
    toml = 'taplo',
    typescript = 'vtsls',
    typescriptreact = 'vtsls',
    vue = 'vue_ls',
    yaml = 'yamlls',
    zig = 'zls',
  },
}

M.config = vim.deepcopy(defaults)

---@type table<string, true> file types already suggested this session
local asked = {}

--- How to open the picker: the key mapped to :LspSuggest, or the command.
---@return string
local function hint()
  for _, map in ipairs(vim.api.nvim_get_keymap('n')) do
    if map.rhs and map.rhs:find('LspSuggest') then
      local lhs = vim.fn.keytrans(map.lhsraw or map.lhs)
      local leader = vim.fn.keytrans(vim.g.mapleader or '\\')
      if vim.startswith(lhs, leader) then
        lhs = '<leader>' .. lhs:sub(#leader + 1)
      end
      return 'Press ' .. lhs
    end
  end
  return 'Run :LspSuggest'
end

---@param name string
---@param status 'running'|'success'|'failed'
---@param message string
local function progress(name, status, message)
  vim.api.nvim_echo({ { message } }, status ~= 'running', {
    id = 'lsp_suggest.' .. name,
    kind = 'progress',
    source = 'lsp_suggest',
    title = 'mason',
    status = status,
  })
end

--- Install a server with mason, record it in lsp-servers.json and start it.
---@param candidate lsp_suggest.Candidate
function M.install(candidate)
  local registry = require('mason-registry')

  local function start()
    store.add_server(candidate.name)
    -- Also attaches to buffers that are already open.
    local ok, err = pcall(vim.lsp.enable, candidate.name)
    if not ok then
      vim.notify(('Could not start %s: %s'):format(candidate.name, err), vim.log.levels.ERROR)
    end
  end

  registry.refresh(vim.schedule_wrap(function()
    local found, pkg = pcall(registry.get_package, candidate.package)
    if not found then
      vim.notify(('mason has no package %s'):format(candidate.package), vim.log.levels.ERROR)
      return
    end
    if pkg:is_installing() then
      vim.notify(('%s is already installing'):format(candidate.package))
      return
    end
    if pkg:is_installed() then
      start()
      progress(candidate.name, 'success', ('%s is already installed'):format(candidate.package))
      return
    end

    progress(candidate.name, 'running', ('Installing %s'):format(candidate.package))
    pkg:install(
      {},
      vim.schedule_wrap(function(success, result)
        if success then
          start()
          progress(candidate.name, 'success', ('Installed %s'):format(candidate.package))
        else
          progress(candidate.name, 'failed', ('Installing %s failed'):format(candidate.package))
          vim.notify(('Installing %s failed: %s'):format(candidate.package, tostring(result)), vim.log.levels.ERROR)
        end
      end)
    )
  end))
end

---@param candidate lsp_suggest.Candidate
---@return string
local function label(candidate)
  local notes = {} ---@type string[]
  if require('mason-registry').is_installed(candidate.package) then
    table.insert(notes, 'installed')
  end
  if candidate.recommended then
    table.insert(notes, 'recommended')
  elseif candidate.general then
    table.insert(notes, ('general, %d file types'):format(candidate.filetypes))
  end
  return #notes > 0 and ('%s  (%s)'):format(candidate.name, table.concat(notes, ', ')) or candidate.name
end

--- Open the picker of servers for `ft` (default: the current buffer's).
---@param ft? string
---@param opts? { all?: boolean } list every server instead of the top few
function M.suggest(ft, opts)
  ft = ft or vim.bo.filetype
  opts = opts or {}
  if ft == '' then
    vim.notify('This buffer has no file type', vim.log.levels.WARN)
    return
  end
  asked[ft] = true

  local candidates = servers.candidates(ft, M.config)
  if #candidates == 0 then
    vim.notify(('mason has no language server for %s'):format(ft), vim.log.levels.WARN)
    return
  end

  local shown = candidates
  if not opts.all then
    shown = vim.tbl_filter(function(c)
      return not c.general
    end, candidates)
    shown = #shown > 0 and vim.list_slice(shown, 1, M.config.shown) or vim.list_slice(candidates, 1, M.config.shown)
  end

  local items = {} ---@type { label: string, candidate?: lsp_suggest.Candidate, action?: string }[]
  for _, candidate in ipairs(shown) do
    table.insert(items, { label = label(candidate), candidate = candidate })
  end
  if #shown < #candidates then
    table.insert(items, { label = ('Show all %d servers…'):format(#candidates), action = 'all' })
  end
  table.insert(items, { label = 'Not now', action = 'later' })
  table.insert(items, { label = ('Never for %s'):format(ft), action = 'never' })

  vim.ui.select(items, {
    prompt = ('Install a language server for %s'):format(ft),
    format_item = function(item)
      return item.label
    end,
    kind = 'lsp_suggest',
  }, function(item)
    if not item or item.action == 'later' then
      return
    elseif item.action == 'all' then
      M.suggest(ft, { all = true })
    elseif item.action == 'never' then
      store.decline(ft)
      vim.notify(('Will not suggest servers for %s again. :LspSuggest still works.'):format(ft))
    else
      M.install(item.candidate)
    end
  end)
end

---@param buf integer
---@return boolean
local function should_suggest(buf)
  if not vim.api.nvim_buf_is_valid(buf) then
    return false
  end
  local ft = vim.bo[buf].filetype
  if vim.bo[buf].buftype ~= '' or ft == '' or vim.api.nvim_buf_get_name(buf) == '' then
    return false
  end
  if asked[ft] or store.is_declined(ft) then
    return false
  end
  if #vim.lsp.get_clients({ bufnr = buf }) > 0 or servers.is_handled(ft) then
    return false
  end
  -- Stay quiet when only general-purpose tools (spell checkers, emmet, ...) exist.
  for _, candidate in ipairs(servers.candidates(ft, M.config)) do
    if not candidate.general then
      return true
    end
  end
  return false
end

---@param buf integer
function M.check(buf)
  if not should_suggest(buf) then
    return
  end
  local ft = vim.bo[buf].filetype
  asked[ft] = true
  if M.config.prompt == 'picker' and vim.api.nvim_get_current_buf() == buf then
    M.suggest(ft)
  else
    vim.notify(('No language server for %s. %s to install one.'):format(ft, hint()), vim.log.levels.INFO)
  end
end

---@param opts? lsp_suggest.Config
function M.setup(opts)
  M.config = vim.tbl_deep_extend('force', defaults, opts or {})

  vim.api.nvim_create_autocmd('FileType', {
    group = vim.api.nvim_create_augroup('config.lsp_suggest', { clear = true }),
    callback = function(ev)
      if vim.bo[ev.buf].buftype == '' then
        vim.defer_fn(function()
          M.check(ev.buf)
        end, M.config.delay)
      end
    end,
  })

  vim.api.nvim_create_user_command('LspSuggest', function(cmd)
    M.suggest(cmd.args ~= '' and cmd.args or nil)
  end, { nargs = '?', complete = 'filetype', desc = 'Install a language server for a file type' })
end

return M
