-- Persistent data for lsp_suggest:
-- - "Never" answers, per machine, in the state folder.
-- - The server list (lsp-servers.json) in the config repo, which
--   lua/plugins/lsp.lua passes to mason as ensure_installed.

local M = {}

M.declined_path = vim.fn.stdpath('state') .. '/lsp-suggest.json'
M.servers_path = vim.fn.stdpath('config') .. '/lsp-servers.json'

---@param path string
---@return any? value nil if the file is missing or not valid JSON
local function read_json(path)
  local ok, lines = pcall(vim.fn.readfile, path)
  if not ok or #lines == 0 then
    return nil
  end
  local decoded_ok, value = pcall(vim.json.decode, table.concat(lines, '\n'))
  return decoded_ok and value or nil
end

---@param path string
---@param value any
local function write_json(path, value)
  vim.fn.mkdir(vim.fs.dirname(path), 'p')
  local text = vim.json.encode(value, { indent = '  ', sort_keys = true })
  vim.fn.writefile(vim.split(text, '\n'), path)
end

---@return table<string, true> declined filetypes
local function declined()
  local data = read_json(M.declined_path)
  return type(data) == 'table' and type(data.never) == 'table' and data.never or {}
end

---@param ft string
---@return boolean
function M.is_declined(ft)
  return declined()[ft] == true
end

---@param ft string
function M.decline(ft)
  local never = declined()
  never[ft] = true
  write_json(M.declined_path, { never = never })
end

---@return string[] servers lspconfig names, sorted
function M.servers()
  local data = read_json(M.servers_path)
  return type(data) == 'table' and data or {}
end

---@param name string lspconfig name
function M.add_server(name)
  local servers = M.servers()
  if vim.list_contains(servers, name) then
    return
  end
  table.insert(servers, name)
  table.sort(servers)
  write_json(M.servers_path, servers)
end

return M
