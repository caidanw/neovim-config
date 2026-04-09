---@module 'lazy'
---@type LazySpec
return {
  { -- Highlight, edit, and navigate code
    'nvim-treesitter/nvim-treesitter',
    -- Neovim 0.12.0 changed captures from table<integer, TSNode> to table<integer, TSNode[]>.
    -- query_predicates.lua uses match[id] expecting a single TSNode; patch it to unwrap the array.
    -- https://github.com/nvim-treesitter/nvim-treesitter/issues/8636
    build = function()
      vim.cmd(':TSUpdate')
      local pred_file = vim.fn.stdpath('data') .. '/lazy/nvim-treesitter/lua/nvim-treesitter/query_predicates.lua'
      local lines = vim.fn.readfile(pred_file)
      -- Already patched
      for _, line in ipairs(lines) do
        if line:match('function get_node') then return end
      end
      -- Insert get_node helper after the opts compatibility line
      for i, line in ipairs(lines) do
        if line:match('local opts = vim%.fn%.has') then
          local helper = {
            '',
            '-- Neovim 0.12.0 changed captures from table<integer, TSNode> to table<integer, TSNode[]>',
            '-- https://github.com/nvim-treesitter/nvim-treesitter/issues/8636',
            'local function get_node(match, id)',
            '  local val = match[id]',
            '  if not val then return nil end',
            '  if type(val) == "table" then return val[1] end',
            '  return val',
            'end',
          }
          for j = #helper, 1, -1 do
            table.insert(lines, i + 1, helper[j])
          end
          -- Replace all match[id] usages
          for k, l in ipairs(lines) do
            lines[k] = l
              :gsub('local node = match%[pred%[2%]%]', 'local node = get_node(match, pred[2])')
              :gsub('local node = match%[capture_id%]', 'local node = get_node(match, capture_id)')
              :gsub('local node = match%[id%]', 'local node = get_node(match, id)')
          end
          vim.fn.writefile(lines, pred_file)
          vim.notify('[nvim-treesitter] Applied Neovim 0.12 captures TSNode[] compatibility patch', vim.log.levels.INFO)
          return
        end
      end
    end,
    main = 'nvim-treesitter.configs', -- Sets main module to use for opts
    -- [[ Configure Treesitter ]] See `:help nvim-treesitter`
    ---@module 'nvim-treesitter.configs'
    ---@type TSConfig
    ---@diagnostic disable-next-line: missing-fields
    opts = {
      ensure_installed = {
        'bash',
        'c',
        'cmake',
        'css',
        'diff',
        'html',
        'javascript',
        'lua',
        'luadoc',
        'make',
        'markdown',
        'markdown_inline',
        'query',
        'regex',
        'scss',
        'typescript',
        'vim',
        'vimdoc',
      },
      -- Autoinstall languages that are not installed
      auto_install = true,
      highlight = {
        enable = true,
        -- Some languages depend on vim's regex highlighting system (such as Ruby) for indent rules.
        --  If you are experiencing weird indenting issues, add the language to
        --  the list of additional_vim_regex_highlighting and disabled languages for indent.
        additional_vim_regex_highlighting = { 'ruby' },
      },
      indent = { enable = true, disable = { 'ruby' } },
    },
    -- There are additional nvim-treesitter modules that you can use to interact
    -- with nvim-treesitter. You should go explore a few and see what interests you:
    --
    --    - Incremental selection: Included, see `:help nvim-treesitter-incremental-selection-mod`
    --    - Show your current context: https://github.com/nvim-treesitter/nvim-treesitter-context
    --    - Treesitter + textobjects: https://github.com/nvim-treesitter/nvim-treesitter-textobjects
  },
  {
    'nvim-treesitter/nvim-treesitter-textobjects',
    dependencies = { 'nvim-treesitter/nvim-treesitter' },
    config = function()
      ---@diagnostic disable-next-line: missing-fields
      require('nvim-treesitter.configs').setup({
        textobjects = {
          move = {
            enable = true,
            goto_next_start = {
              [']f'] = '@function.outer',
              [']c'] = '@class.outer',
              [']a'] = '@parameter.inner',
            },
            goto_next_end = {
              [']F'] = '@function.outer',
              [']C'] = '@class.outer',
              [']A'] = '@parameter.inner',
            },
            goto_previous_start = {
              ['[f'] = '@function.outer',
              ['[c'] = '@class.outer',
              ['[a'] = '@parameter.inner',
            },
            goto_previous_end = {
              ['[F'] = '@function.outer',
              ['[C'] = '@class.outer',
              ['[A'] = '@parameter.inner',
            },
          },
        },
      })
    end,
  },
  {
    'nvim-treesitter/nvim-treesitter-context',

    -- Neovim 0.12.0 changed LanguageTree:parse() so that any non-nil callback
    -- triggers async parsing, which has a nil-node bug. The plugin passes a dummy
    -- callback as a 0.11 workaround; we patch it out after every install/update.
    -- https://github.com/nvim-treesitter/nvim-treesitter-context/issues/XXX
    build = function()
      local context_file = vim.fn.stdpath('data') .. '/lazy/nvim-treesitter-context/lua/treesitter-context/context.lua'
      local lines = vim.fn.readfile(context_file)
      for i, line in ipairs(lines) do
        if line:match('root_tree:parse%(range, function%(%.%.%.%) end%)') then
          -- Remove the diagnostic-disable comment on the preceding line
          if i > 1 and lines[i - 1]:match('redundant%-parameter') then
            table.remove(lines, i - 1)
          end
          lines[i] = line:gsub('root_tree:parse%(range, function%(%.%.%.%) end%)', 'root_tree:parse(range)')
          vim.fn.writefile(lines, context_file)
          vim.notify('[treesitter-context] Applied Neovim 0.12 async-parse compatibility patch', vim.log.levels.INFO)
          return
        end
      end
    end,

    ---@module 'treesitter-context'
    ---@type TSContext.UserConfig
    opts = {
      max_lines = 5,
    },

    init = function()
      local tsc = require('treesitter-context')
      require('snacks').toggle
        .new({
          name = 'Treesitter Context',
          get = tsc.enabled,
          set = function(state)
            if state then
              tsc.enable()
            else
              tsc.disable()
            end
          end,
        })
        :map('<leader>ut')
    end,
  },
}
