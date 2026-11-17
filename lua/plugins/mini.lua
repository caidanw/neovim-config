-- Register mini.ai textobjects with which-key so they show up in its popup.
---@param opts table
local function ai_whichkey(opts)
  local objects = {
    { ' ', desc = 'whitespace' },
    { '"', desc = '" string' },
    { "'", desc = "' string" },
    { '(', desc = '() block' },
    { ')', desc = '() block with ws' },
    { '<', desc = '<> block' },
    { '>', desc = '<> block with ws' },
    { '?', desc = 'user prompt' },
    { 'U', desc = 'use/call without dot' },
    { '[', desc = '[] block' },
    { ']', desc = '[] block with ws' },
    { '_', desc = 'underscore' },
    { '`', desc = '` string' },
    { 'a', desc = 'argument' },
    { 'b', desc = ')]} block' },
    { 'c', desc = 'class' },
    { 'd', desc = 'digit(s)' },
    { 'e', desc = 'CamelCase / snake_case' },
    { 'f', desc = 'function' },
    { 'g', desc = 'entire file' },
    { 'i', desc = 'indent' },
    { 'o', desc = 'block, conditional, loop' },
    { 'q', desc = 'quote `"\'' },
    { 't', desc = 'tag' },
    { 'u', desc = 'use/call' },
    { '{', desc = '{} block' },
    { '}', desc = '{} with ws' },
  }

  ---@type wk.Spec[]
  local ret = { mode = { 'o', 'x' } }
  ---@type table<string, string>
  local mappings = vim.tbl_extend('force', {}, {
    around = 'a',
    inside = 'i',
    around_next = 'an',
    inside_next = 'in',
    around_last = 'al',
    inside_last = 'il',
  }, opts.mappings or {})
  mappings.goto_left = nil
  mappings.goto_right = nil

  for name, prefix in pairs(mappings) do
    name = name:gsub('^around_', ''):gsub('^inside_', '')
    ret[#ret + 1] = { prefix, group = name }
    for _, obj in ipairs(objects) do
      local desc = obj.desc
      if prefix:sub(1, 1) == 'i' then
        desc = desc:gsub(' with ws', '')
      end
      ret[#ret + 1] = { prefix .. obj[1], desc = obj.desc }
    end
  end

  require('which-key').add(ret, { notify = false })
end

---@module 'lazy'
---@type LazySpec
return {
  {
    'nvim-mini/mini.nvim',
    config = function()
      -- Icons. Plugins that only know nvim-web-devicons get a compatible shim.
      require('mini.icons').setup()
      MiniIcons.mock_nvim_web_devicons()

      -- Extra around/inside textobjects, e.g. `va)`, `ci'`, `daf` (function).
      local ai = require('mini.ai')
      ai.setup({
        -- Neovim 0.12 has built-in `an`/`in` (select by syntax node) and 0.13
        -- adds `al`/`il` (whole buffer, current line). Move mini.ai's next/last
        -- variants out of the way, as `:h MiniAi-default-an-in` suggests.
        -- (`aa`/`ii` would shadow mini.ai's own `a` argument textobject.)
        mappings = {
          around_next = 'aN',
          inside_next = 'iN',
          around_last = 'aL',
          inside_last = 'iL',
        },
        n_lines = 500,
        search_method = 'cover_or_nearest',
        custom_textobjects = {
          f = ai.gen_spec.treesitter({ a = '@function.outer', i = '@function.inner' }),
          c = ai.gen_spec.treesitter({ a = '@class.outer', i = '@class.inner' }),
          t = { '<([%p%w]-)%f[^<%w][^<>]->.-</%1>', '^<.->().*()</[^/]->$' }, -- tag
          d = { '%f[%d]%d+' }, -- digits
          u = ai.gen_spec.function_call(), -- call
          U = ai.gen_spec.function_call({ name_pattern = '[%w_]' }), -- call, without dots in the name
          o = ai.gen_spec.treesitter({ -- block, conditional, loop
            a = { '@block.outer', '@conditional.outer', '@loop.outer' },
            i = { '@block.inner', '@conditional.inner', '@loop.inner' },
          }),
          g = function() -- whole buffer
            local from = { line = 1, col = 1 }
            local to = { line = vim.fn.line('$'), col = math.max(vim.fn.getline('$'):len(), 1) }
            return { from = from, to = to }
          end,
        },
      })
      vim.schedule(function()
        ai_whichkey(require('mini.ai').config)
      end)

      -- Add/delete/replace surroundings under the `gs` prefix.
      require('mini.surround').setup({
        n_lines = 500,
        mappings = {
          add = 'gsa',
          delete = 'gsd',
          find = 'gsf',
          find_left = 'gsF',
          highlight = 'gsh',
          replace = 'gsr',
          update_n_lines = 'gsn',
        },
      })

      local statusline = require('mini.statusline')
      statusline.setup({ use_icons = vim.g.have_nerd_font })
      ---@diagnostic disable-next-line: duplicate-set-field
      statusline.section_location = function()
        return '%2l:%-2v'
      end

      -- Highlight TODO-style keywords followed by a colon, and hex colors.
      local hipatterns = require('mini.hipatterns')
      local function keyword(words, group)
        local patterns = vim.tbl_map(function(word)
          return '%f[%w]()' .. word .. '()%s*:'
        end, words)
        return { pattern = patterns, group = group }
      end
      local hex_color = hipatterns.gen_highlighter.hex_color({
        -- In CSS-like files the language server already colors these (vim.lsp.document_color).
        filter = function(buf)
          return not vim.tbl_contains({ 'css', 'scss', 'less', 'sass' }, vim.bo[buf].filetype)
        end,
      })
      hipatterns.setup({
        highlighters = {
          fixme = keyword({ 'FIXME', 'FIX', 'BUG' }, 'MiniHipatternsFixme'),
          hack = keyword({ 'HACK', 'WARN', 'WARNING' }, 'MiniHipatternsHack'),
          todo = keyword({ 'TODO' }, 'MiniHipatternsTodo'),
          note = keyword({ 'NOTE', 'INFO', 'PERF' }, 'MiniHipatternsNote'),
          hex_color = hex_color,
        },
      })
    end,
  },
}
