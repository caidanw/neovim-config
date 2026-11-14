---@module 'lazy'
---@type LazySpec
return {
  { -- Highlight, edit, and navigate code
    'nvim-treesitter/nvim-treesitter',
    branch = 'main', -- the rewrite; master is frozen. Requires the tree-sitter CLI to compile parsers.
    lazy = false, -- rewrite does not support lazy-loading
    build = ':TSUpdate',

    -- Parsers to keep installed/updated. The rewrite has no `configs` module,
    -- no `auto_install`, and no `highlight`/`indent` options: we install here
    -- and enable per-buffer in the FileType autocmd below.
    config = function()
      local ensure_installed = {
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
      }

      require('nvim-treesitter').install(ensure_installed)

      -- Enable highlighting + experimental indent per buffer. Auto-install a
      -- missing supported parser on first open, then attach once it is ready.
      vim.api.nvim_create_autocmd('FileType', {
        callback = function(ev)
          local lang = vim.treesitter.language.get_lang(ev.match)

          -- Ruby relies on vim's regex indent; skip treesitter indent for it.
          if lang ~= 'ruby' then
            vim.bo[ev.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
          end

          if not vim.tbl_contains(require('nvim-treesitter.config').get_available(), lang) then
            return
          end

          if pcall(vim.treesitter.start, ev.buf, lang) then
            return
          end

          -- Parser missing: install async, then start highlighting when done.
          require('nvim-treesitter').install(lang):await(function()
            pcall(vim.treesitter.start, ev.buf, lang)
          end)
        end,
      })
    end,
  },
  {
    'nvim-treesitter/nvim-treesitter-textobjects',
    branch = 'main',
    dependencies = { 'nvim-treesitter/nvim-treesitter' },
    config = function()
      require('nvim-treesitter-textobjects').setup({
        move = { set_jumps = true },
      })

      -- move keymaps: (key, capture) pairs shared across the four directions.
      local move = require('nvim-treesitter-textobjects.move')
      local targets = {
        { 'f', '@function.outer' },
        { 'c', '@class.outer' },
        { 'a', '@parameter.inner' },
      }

      for _, target in ipairs(targets) do
        local key, capture = target[1], target[2]
        local modes = { 'n', 'x', 'o' }

        vim.keymap.set(modes, ']' .. key, function()
          move.goto_next_start(capture, 'textobjects')
        end)
        vim.keymap.set(modes, ']' .. key:upper(), function()
          move.goto_next_end(capture, 'textobjects')
        end)
        vim.keymap.set(modes, '[' .. key, function()
          move.goto_previous_start(capture, 'textobjects')
        end)
        vim.keymap.set(modes, '[' .. key:upper(), function()
          move.goto_previous_end(capture, 'textobjects')
        end)
      end
    end,
  },
  {
    'nvim-treesitter/nvim-treesitter-context',

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
