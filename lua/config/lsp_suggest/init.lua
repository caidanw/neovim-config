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

---@alias lsp_suggest.Item { label: string, candidate?: lsp_suggest.Candidate, action?: 'all'|'later'|'never', preview: { text: string, ft: string } }

---@param candidate lsp_suggest.Candidate
---@return { text: string, hl?: string }[] tags shown after the name
local function tags(candidate)
  local result = {} ---@type { text: string, hl?: string }[]
  if candidate.deprecation then
    table.insert(result, { text = 'deprecated', hl = 'DiagnosticWarn' })
  end
  if require('mason-registry').is_installed(candidate.package) then
    table.insert(result, { text = 'installed', hl = 'DiagnosticOk' })
  end
  if candidate.recommended then
    table.insert(result, { text = 'recommended', hl = 'DiagnosticInfo' })
  end
  if candidate.general then
    table.insert(result, { text = ('general, %d file types'):format(#candidate.filetypes) })
  end
  return result
end

--- Markdown shown in the picker's preview pane (snacks only).
---@param candidate lsp_suggest.Candidate
---@param ft string
---@return string
local function details(candidate, ft)
  local lines = { '# ' .. candidate.name, '' }
  if candidate.deprecation then
    vim.list_extend(lines, {
      ('> **Deprecated** since %s: %s'):format(candidate.deprecation.since, candidate.deprecation.message),
      '',
    })
  end
  if candidate.description then
    vim.list_extend(lines, { candidate.description, '' })
  end
  local function row(key, value)
    if value and value ~= '' then
      table.insert(lines, ('- **%s:** %s'):format(key, value))
    end
  end
  local installed = require('mason-registry').is_installed(candidate.package)
  row('Status', installed and 'installed' or 'not installed')
  row('Recommended', candidate.recommended and ('yes, for %s'):format(ft) or nil)
  row('Categories', table.concat(candidate.categories, ', '))
  row('Languages', table.concat(candidate.languages, ', '))
  row('File types', table.concat(candidate.filetypes, ', '))
  row('License', table.concat(candidate.licenses, ', '))
  row('Homepage', candidate.homepage)
  row('Mason package', candidate.package)
  if candidate.homepage then
    vim.list_extend(lines, { '', '`<C-o>` opens the homepage.' })
  end
  return table.concat(lines, '\n')
end

---@param item lsp_suggest.Item
---@param highlighted? boolean true when snacks asks for highlight chunks
---@return string|{ [1]: string, [2]?: string }[]
local function format_item(item, highlighted)
  local candidate = item.candidate
  if not candidate then
    return highlighted and { { item.label, 'Comment' } } or item.label
  end

  local item_tags = tags(candidate)
  if not highlighted then
    local tag_text = vim.tbl_map(function(tag)
      return tag.text
    end, item_tags)
    local text = #tag_text > 0 and ('%s (%s)'):format(candidate.name, table.concat(tag_text, ', ')) or candidate.name
    return candidate.description and ('%s - %s'):format(text, candidate.description) or text
  end

  local chunks = { { candidate.name, candidate.deprecation and 'Comment' or nil } }
  for _, tag in ipairs(item_tags) do
    table.insert(chunks, { ' ' })
    table.insert(chunks, { '[' .. tag.text .. ']', tag.hl or 'Comment' })
  end
  if candidate.description then
    table.insert(chunks, { '  ' .. candidate.description, 'Comment' })
  end
  return chunks
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

  local items = {} ---@type lsp_suggest.Item[]
  local function add(item, preview)
    item.preview = { text = preview, ft = 'markdown' }
    table.insert(items, item)
  end
  for _, candidate in ipairs(shown) do
    add({ label = candidate.name, candidate = candidate }, details(candidate, ft))
  end
  if #shown < #candidates then
    add(
      { label = ('Show all %d servers…'):format(#candidates), action = 'all' },
      'List every server mason can install for ' .. ft .. ', including general-purpose tools.'
    )
  end
  add({ label = 'Not now', action = 'later' }, 'Close. The notification comes back next session.')
  add(
    { label = ('Never for %s'):format(ft), action = 'never' },
    ('Stop suggesting servers for %s on this machine. `:LspSuggest` still opens this picker.'):format(ft)
  )

  vim.ui.select(items, {
    prompt = ('Install a language server for %s'):format(ft),
    format_item = format_item,
    kind = 'lsp_suggest',
    -- Read only by snacks' vim.ui.select; other implementations ignore it.
    snacks = {
      preview = 'preview',
      layout = { hidden = {} },
      actions = {
        open_homepage = function(_, picked)
          local url = picked and picked.item and picked.item.candidate and picked.item.candidate.homepage
          if url then
            vim.ui.open(url)
          end
        end,
      },
      win = {
        input = { keys = { ['<C-o>'] = { 'open_homepage', mode = { 'n', 'i' }, desc = 'Open homepage' } } },
        list = { keys = { ['<C-o>'] = { 'open_homepage', desc = 'Open homepage' } } },
      },
    },
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
  -- Stay quiet when the only options are general-purpose tools (spell
  -- checkers, emmet, ...) or deprecated servers.
  for _, candidate in ipairs(servers.candidates(ft, M.config)) do
    if not candidate.general and not candidate.deprecation then
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
