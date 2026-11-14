-- Per-directory sessions on top of `:mksession`.
--
-- File names match persistence.nvim (cwd with path separators replaced by
-- `%`, plus `%%branch` off main/master), so sessions it saved still load.

local M = {}

local dir = vim.fn.stdpath('state') .. '/sessions/'

---@return string?
local function git_branch()
  local ok, result = pcall(function()
    return vim.system({ 'git', 'branch', '--show-current' }, { text = true }):wait()
  end)
  if ok and result.code == 0 then
    local branch = vim.trim(result.stdout)
    return branch ~= '' and branch or nil
  end
end

---@param opts? { branch?: boolean }
---@return string
function M.file(opts)
  local name = vim.fn.getcwd():gsub('[\\/:]+', '%%')
  if not opts or opts.branch ~= false then
    local branch = git_branch()
    if branch and branch ~= 'main' and branch ~= 'master' then
      name = name .. '%%' .. branch:gsub('[\\/:]+', '%%')
    end
  end
  return dir .. name .. '.vim'
end

function M.save()
  vim.fn.mkdir(dir, 'p')
  vim.cmd('mksession! ' .. vim.fn.fnameescape(M.file()))
end

--- Load the session for the current directory, preferring the current branch.
---@return boolean loaded
function M.load()
  for _, file in ipairs({ M.file(), M.file({ branch = false }) }) do
    if vim.fn.filereadable(file) == 1 then
      vim.cmd('silent! source ' .. vim.fn.fnameescape(file))
      return true
    end
  end
  return false
end

--- cd into a project, then restore its session or fall back to the file picker.
---@param project string
function M.open_project(project)
  vim.fn.chdir(project)
  if not M.load() then
    Snacks.picker.files()
  end
end

--- True if any listed buffer is a real file worth restoring.
local function has_file_buffers()
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    local bo = vim.bo[buf]
    if bo.buflisted and bo.buftype == '' and vim.api.nvim_buf_get_name(buf) ~= '' and not vim.tbl_contains({ 'gitcommit', 'gitrebase', 'jj' }, bo.filetype) then
      return true
    end
  end
  return false
end

function M.setup()
  local group = vim.api.nvim_create_augroup('config.session', { clear = true })

  -- Start autosaving only after a real file is read, so opening the dashboard
  -- and quitting does not overwrite the previous session.
  vim.api.nvim_create_autocmd('BufReadPre', {
    group = group,
    once = true,
    callback = function()
      vim.api.nvim_create_autocmd('VimLeavePre', {
        group = group,
        callback = function()
          if has_file_buffers() then
            M.save()
          end
        end,
      })
    end,
  })

  vim.api.nvim_create_user_command('SessionRestore', function()
    if not M.load() then
      vim.notify('No session for ' .. vim.fn.getcwd(), vim.log.levels.WARN)
    end
  end, { desc = 'Restore the session for the current directory' })
end

return M
