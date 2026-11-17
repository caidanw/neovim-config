-- Which language servers handle which file types.
--
-- The source is every lsp/*.lua config on the runtimepath (nvim-lspconfig's and
-- ours). Loading ~400 of those takes ~130 ms, so the result is cached in the
-- cache folder and rebuilt only when the set of files or their mtimes change.

local M = {}

local cache_path = vim.fn.stdpath('cache') .. '/lsp-suggest-index.json'

---@type table<string, string[]>? lspconfig name -> filetypes
local index

---@param files string[]
---@return string
local function fingerprint(files)
  local newest = 0
  for _, file in ipairs(files) do
    local stat = vim.uv.fs_stat(file)
    if stat and stat.mtime.sec > newest then
      newest = stat.mtime.sec
    end
  end
  return #files .. ':' .. newest
end

---@return table<string, string[]> lspconfig name -> filetypes
function M.index()
  if index then
    return index
  end

  local files = vim.api.nvim_get_runtime_file('lsp/*.lua', true)
  local key = fingerprint(files)
  local ok, cached = pcall(function()
    return vim.json.decode(table.concat(vim.fn.readfile(cache_path), '\n'))
  end)
  if ok and type(cached) == 'table' and cached.key == key then
    index = cached.servers
    return index
  end

  index = {}
  for _, file in ipairs(files) do
    local name = vim.fn.fnamemodify(file, ':t:r')
    local loaded, config = pcall(dofile, file)
    -- Our own lsp/*.lua files usually only add settings; keep the first
    -- filetypes list found for each name.
    if loaded and type(config) == 'table' and type(config.filetypes) == 'table' and not index[name] then
      index[name] = config.filetypes
    end
  end
  vim.fn.mkdir(vim.fs.dirname(cache_path), 'p')
  vim.fn.writefile({ vim.json.encode({ key = key, servers = index }) }, cache_path)
  return index
end

--- True if an enabled language server is configured for `ft`, whether or not
--- it has attached (it may be waiting for a project root).
---@param ft string
---@return boolean
function M.is_handled(ft)
  for name in pairs(M.index()) do
    if vim.lsp.is_enabled(name) then
      local filetypes = vim.lsp.config[name] and vim.lsp.config[name].filetypes or {}
      if vim.list_contains(filetypes, ft) then
        return true
      end
    end
  end
  return false
end

---@class lsp_suggest.Candidate
---@field name string lspconfig name, e.g. "basedpyright"
---@field package string mason package, e.g. "basedpyright"
---@field filetypes string[] every file type the server covers
---@field recommended boolean
---@field general boolean covers so many file types that it is not specific to `ft`
---@field description? string from the mason registry
---@field homepage? string
---@field licenses string[]
---@field languages string[]
---@field categories string[] e.g. { "LSP" } or { "LSP", "Linter" }
---@field deprecation? { since: string, message: string }

--- Servers mason can install for `ft`, best first: deprecated servers last,
--- then the recommended one, then the most specific (fewest file types), then
--- by name.
---@param ft string
---@param opts { recommended: table<string, string>, max_filetypes: integer }
---@return lsp_suggest.Candidate[]
function M.candidates(ft, opts)
  local to_package = require('mason-lspconfig').get_mappings().lspconfig_to_package
  local registry = require('mason-registry')
  local result = {} ---@type lsp_suggest.Candidate[]
  for name, filetypes in pairs(M.index()) do
    local pkg = to_package[name]
    if pkg and vim.list_contains(filetypes, ft) then
      local found, mason_pkg = pcall(registry.get_package, pkg)
      local spec = found and mason_pkg.spec or {}
      table.insert(result, {
        name = name,
        package = pkg,
        filetypes = filetypes,
        recommended = opts.recommended[ft] == name,
        general = #filetypes > opts.max_filetypes,
        description = spec.description,
        homepage = spec.homepage,
        licenses = spec.licenses or {},
        languages = spec.languages or {},
        categories = spec.categories or {},
        deprecation = spec.deprecation,
      })
    end
  end
  table.sort(result, function(a, b)
    if (a.deprecation == nil) ~= (b.deprecation == nil) then
      return a.deprecation == nil
    end
    if a.recommended ~= b.recommended then
      return a.recommended
    end
    if a.general ~= b.general then
      return not a.general
    end
    if #a.filetypes ~= #b.filetypes then
      return #a.filetypes < #b.filetypes
    end
    return a.name < b.name
  end)
  return result
end

return M
