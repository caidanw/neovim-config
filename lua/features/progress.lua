-- A small fidget-style corner widget for Neovim's built-in progress messages.
--
-- Anything that calls nvim_echo() with kind = 'progress' fires the Progress
-- event: LSP progress (lua/config/lsp.lua), Mason installs from :LspSuggest,
-- and plugins that use the native API. Each task gets one line in the
-- bottom-right corner, right-aligned above the statusline:
--
--   Loading workspace 112/242  48%  lua_ls ⠹
--   Installing taplo         2.1s  mason ✓
--
-- Running tasks show their percent; finished ones show how long they took,
-- measured here from their first to their last message. Finished tasks stay
-- for `linger` ms, then disappear.

local M = {}

M.config = {
  linger = 2000, -- ms a finished task stays visible
  interval = 80, -- ms between spinner frames
  spinner = { '⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏' },
  icons = { success = '✓', failed = '✗', cancel = '✗' },
}

---@class progress.Task
---@field id integer|string message id from nvim_echo
---@field title string e.g. "lua_ls" or "mason"
---@field text string e.g. "Loading workspace 112/242"
---@field percent? integer
---@field status 'running'|'success'|'failed'|'cancel'
---@field started integer hrtime of the first message
---@field elapsed? number seconds from first to last message, once finished

local tasks = {} ---@type progress.Task[] in the order they started
local ns = vim.api.nvim_create_namespace('features.progress')
local buf, win ---@type integer?, integer?
local timer ---@type uv.uv_timer_t?
local frame = 1

---@param id integer|string
---@return progress.Task?, integer?
local function find(id)
  for i, task in ipairs(tasks) do
    if task.id == id then
      return task, i
    end
  end
end

local function close()
  if win and vim.api.nvim_win_is_valid(win) then
    vim.api.nvim_win_close(win, true)
  end
  win = nil
end

---@param task progress.Task
---@return { [1]: string, [2]?: string }[] pieces of one line
local function pieces(task)
  local result = { { task.text } }
  if task.status == 'running' and task.percent and task.percent > 0 then
    table.insert(result, { ('  %d%%'):format(task.percent), 'Comment' })
  elseif task.elapsed then
    local duration = task.elapsed < 60 and ('%.1fs'):format(task.elapsed) or ('%dm %02ds'):format(math.floor(task.elapsed / 60), math.floor(task.elapsed % 60))
    table.insert(result, { '  ' .. duration, 'Comment' })
  end
  table.insert(result, { '  ' .. task.title, 'Title' })
  local icon = task.status == 'running' and M.config.spinner[frame] or M.config.icons[task.status] or '?'
  local icon_hl = ({ running = 'DiagnosticInfo', success = 'DiagnosticOk' })[task.status] or 'DiagnosticError'
  table.insert(result, { ' ' .. icon, icon_hl })
  return result
end

local function render()
  if #tasks == 0 then
    close()
    return
  end

  -- Build right-aligned lines and remember where each highlight goes.
  local rows = {} ---@type { text: string, marks: table[], pad?: integer }[]
  local width = 0
  for _, task in ipairs(tasks) do
    local text, marks = '', {}
    for _, piece in ipairs(pieces(task)) do
      if piece[2] then
        table.insert(marks, { col = #text, end_col = #text + #piece[1], hl = piece[2] })
      end
      text = text .. piece[1]
    end
    table.insert(rows, { text = text, marks = marks })
    width = math.max(width, vim.fn.strdisplaywidth(text))
  end
  width = math.min(width, math.max(vim.o.columns - 4, 1))

  if not (buf and vim.api.nvim_buf_is_valid(buf)) then
    buf = vim.api.nvim_create_buf(false, true)
  end
  local lines = {}
  for _, row in ipairs(rows) do
    local pad = math.max(width - vim.fn.strdisplaywidth(row.text), 0)
    row.pad = pad
    table.insert(lines, (' '):rep(pad) .. row.text)
  end
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  for i, row in ipairs(rows) do
    for _, mark in ipairs(row.marks) do
      vim.api.nvim_buf_set_extmark(buf, ns, i - 1, row.pad + mark.col, {
        end_col = row.pad + mark.end_col,
        hl_group = mark.hl,
      })
    end
  end

  -- Bottom-right corner, just above the statusline and command line.
  local statusline = vim.o.laststatus > 0 and 1 or 0
  local config = {
    relative = 'editor',
    anchor = 'SE',
    row = vim.o.lines - vim.o.cmdheight - statusline,
    col = vim.o.columns - 1,
    width = width,
    height = #lines,
    style = 'minimal',
    border = 'none',
    focusable = false,
    zindex = 45, -- below pickers and other popups
  }
  if win and vim.api.nvim_win_is_valid(win) then
    vim.api.nvim_win_set_config(win, config)
  else
    config.noautocmd = true
    win = vim.api.nvim_open_win(buf, false, config)
    -- See-through background, so the widget floats over the text like fidget.
    vim.wo[win].winblend = 100
    vim.wo[win].winhighlight = 'Normal:Normal'
  end
end

--- Render on the main loop; windows cannot open during textlock.
local schedule_render = vim.schedule_wrap(function()
  pcall(render)
end)

local function update_spinner()
  local running = vim.iter(tasks):any(function(task)
    return task.status == 'running'
  end)
  if running and not timer then
    timer = assert(vim.uv.new_timer())
    timer:start(0, M.config.interval, function()
      frame = frame % #M.config.spinner + 1
      schedule_render()
    end)
  elseif not running and timer then
    timer:stop()
    timer:close()
    timer = nil
  end
end

--- The event's `text` is the message's chunks: strings or { text, hl } pairs.
---@param text any
---@return string
local function to_string(text)
  if type(text) ~= 'table' then
    return text and tostring(text) or ''
  end
  local parts = {} ---@type string[]
  for _, chunk in ipairs(text) do
    table.insert(parts, type(chunk) == 'table' and tostring(chunk[1] or '') or tostring(chunk))
  end
  return table.concat(parts)
end

---@param data vim.event.progress.data
local function on_progress(data)
  if not data or data.id == nil then
    return
  end
  local task = find(data.id)
  if not task then
    task = { id = data.id, title = '', text = '', status = 'running', started = vim.uv.hrtime() }
    table.insert(tasks, task)
  end
  task.title = data.title or data.source or ''
  task.text = to_string(data.text)
  task.percent = data.percent
  task.status = data.status or 'running'
  if task.status ~= 'running' then
    task.elapsed = (vim.uv.hrtime() - task.started) / 1e9
  end

  if task.status ~= 'running' then
    local id = task.id
    vim.defer_fn(function()
      local current, index = find(id)
      if current and current.status ~= 'running' and index then
        table.remove(tasks, index)
        schedule_render()
      end
    end, M.config.linger)
  end
  update_spinner()
  schedule_render()
end

function M.setup()
  -- The widget replaces the progress text in the command line.
  vim.opt.messagesopt:remove('progress:c')
  vim.opt.messagesopt:append('progress:')

  local group = vim.api.nvim_create_augroup('features.progress', { clear = true })
  vim.api.nvim_create_autocmd('Progress', {
    group = group,
    callback = function(ev)
      on_progress(ev.data)
    end,
  })
  vim.api.nvim_create_autocmd('VimResized', { group = group, callback = schedule_render })
end

return M

-- vim: ts=2 sts=2 sw=2 et
