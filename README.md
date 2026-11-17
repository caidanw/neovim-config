# neovim-config

My Neovim config. It targets Neovim 0.12 and uses built-in features where Neovim has them: completion, LSP setup, sessions, commenting, and incremental selection. Plugins cover the rest, managed by [lazy.nvim](https://github.com/folke/lazy.nvim).

## Install

You need:

- Neovim 0.12 or later
- `git`, a C compiler, and the [`tree-sitter` CLI](https://github.com/tree-sitter/tree-sitter/tree/master/crates/cli). nvim-treesitter compiles parsers with them.
- Node.js. Mason installs the TypeScript, CSS, and JSON language servers and prettier with it.
- `rg` and `fd` for the file and grep pickers
- A [Nerd Font](https://www.nerdfonts.com). Without one, set `vim.g.have_nerd_font = false` in `init.lua`.
- Optional: `lazygit` for `<leader>gg`, and a WakaTime API key for vim-wakatime

On macOS:

```sh
brew install neovim git tree-sitter-cli node ripgrep fd lazygit
```

Then clone the config and start Neovim:

```sh
git clone git@github.com:caidanw/neovim-config.git ~/.config/nvim
nvim
```

On first start, lazy.nvim installs the plugins, nvim-treesitter compiles parsers, and Mason installs the formatters and the language servers listed in `lsp-servers.json`. Run `:checkhealth` if anything fails.

## Add a language server

When you open a file type that no installed server handles, a notification says so. Press `<leader>cL` (or run `:LspSuggest`) to pick a server. Mason installs it, it starts in the open buffers, and its name is added to `lsp-servers.json`. Commit that file so other machines install the server too.

Each server in the picker shows its Mason description. The preview pane lists its categories, languages, file types, license, and homepage. Press `<C-o>` to open the homepage. Deprecated servers are listed last, with the reason.

The picker also has **Never for <file type>**. That answer is saved per machine in `~/.local/state/nvim/lsp-suggest.json`. `:LspSuggest` still opens the picker for a declined file type.

## Layout

```text
init.lua                 Sets the leader key and loads lua/config/
lua/config/
  options.lua            Editor options
  keymaps.lua            General keymaps
  autocmds.lua           General autocommands
  lsp.lua                LSP keymaps, diagnostics, progress messages
  progress.lua           Corner widget for progress messages
  completion.lua         Built-in completion as you type
  session.lua            Per-directory sessions
  lsp_suggest/           Offers to install a language server for new file types
  lazy.lua               Installs lazy.nvim and loads lua/plugins/
  macro_recording.lua    Turns `q` macro recording on and off
lua/plugins/             One file per plugin or group of plugins
lsp/                     Language server settings, merged over nvim-lspconfig's defaults
lsp-servers.json         Language servers Mason installs on startup
ftplugin/                Filetype overrides
colors/                  Local colorschemes
spell/                   Personal spelling words
```

`lazy-lock.json` pins every plugin to a commit. Run `:Lazy update` to move the pins, then commit the file.

## Built-in features in use

| Feature | Setup |
|---|---|
| Completion | `'autocomplete'` with the language server first, then buffer words (`lua/config/completion.lua`) |
| Language servers | `vim.lsp.config` files in `lsp/`, enabled by mason-lspconfig |
| Progress | LSP and Mason progress become native progress messages, drawn in the bottom-right corner by `lua/config/progress.lua` |
| Color swatches in CSS | `vim.lsp.document_color` |
| Matching tag rename | `vim.lsp.linked_editing_range` |
| Sessions | `:mksession` on exit, restored from the dashboard or projects picker (`lua/config/session.lua`) |
| Commenting | `gc` and `gcc` |
| Select by syntax node | `an` and `in` in visual mode |

## Plugins

| Plugin | Use |
|---|---|
| [snacks.nvim](https://github.com/folke/snacks.nvim) | Pickers, explorer, dashboard, notifications, terminal, lazygit, toggles |
| [mini.nvim](https://github.com/nvim-mini/mini.nvim) | Textobjects (`ai`), surround (`gs`), statusline, icons, TODO and hex color highlights |
| [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter) | Parser installs, indent; plus `-textobjects` for `]f`-style moves and `-context` for a sticky scope header |
| [nvim-lspconfig](https://github.com/neovim/nvim-lspconfig) | Default language server configs |
| [mason.nvim](https://github.com/mason-org/mason.nvim) | Installs language servers and formatters, with mason-lspconfig and mason-tool-installer |
| [conform.nvim](https://github.com/stevearc/conform.nvim) | Format on save with stylua, prettier, and ruff |
| [gitsigns.nvim](https://github.com/lewis6991/gitsigns.nvim) | Git change markers in the sign column |
| [oil.nvim](https://github.com/stevearc/oil.nvim) | Edit directories as buffers |
| [flash.nvim](https://github.com/folke/flash.nvim) | Jump with search labels (`s`, `S`) |
| [dial.nvim](https://github.com/monaqa/dial.nvim) | `<C-a>` and `<C-x>` on booleans, dates, and keywords as well as numbers |
| [which-key.nvim](https://github.com/folke/which-key.nvim) | Shows the keys available after a prefix |
| [render-markdown.nvim](https://github.com/MeanderingProgrammer/render-markdown.nvim) | Rendered Markdown, off by default (`<leader>um`) |
| [lazydev.nvim](https://github.com/folke/lazydev.nvim) | Neovim API types when editing this config |
| [schemastore.nvim](https://github.com/b0o/SchemaStore.nvim) | JSON and YAML schemas |
| [vim-wakatime](https://github.com/wakatime/vim-wakatime) | Coding time tracking |
| nordic, everforest, onenord | Colorschemes. Nordic is the default; switch with `<leader>uC`. |

## Keys

The leader key is Space. Press it and wait to see every group in which-key, or search all keys with `<leader>sk`.

| Keys | Action |
|---|---|
| `<leader>sf`, `<leader>sg`, `<leader><leader>` | Find files, grep, switch buffers |
| `<leader>e`, `<leader>fo` | File explorer, oil |
| `grr`, `gri`, `grt`, `gO` | References, implementations, type definitions, document symbols |
| `grn`, `gra`, `K`, `<C-s>` | Rename, code action, hover, signature help (Neovim defaults) |
| `gd`, `gD` | Definition, declaration |
| `<leader>cL` | Install a language server for the current file type |
| `<C-y>`, `<C-n>`, `<C-p>`, `<C-space>` | Accept, next, and previous completion; ask the language server |
| `]f`, `]c`, `]a` | Next function, class, or argument. In diff mode, `]c` jumps to the next change. |
| `<leader>u` | Toggles: format on save, inlay hints, wrap, spelling, and more |
| `<leader>gg` | lazygit |

## Credits

This config started as a fork of [kickstart-modular.nvim](https://github.com/dam9000/kickstart-modular.nvim), which is based on [kickstart.nvim](https://github.com/nvim-lua/kickstart.nvim). See `LICENSE.md`.
