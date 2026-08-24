# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A personal Neovim configuration, originally based on kickstart.nvim but since
restructured into a flat, custom layout. Plugin management is via
[lazy.nvim](https://github.com/folke/lazy.nvim).

## Commands

There is no build/test/lint pipeline — this is an editor config, validated by
loading it.

- **Sanity-check after edits** (catches broken `require` paths or Lua syntax
  errors from file moves/renames):
  ```sh
  nvim --headless -c "lua vim.wait(2000)" -c "qa"
  ```
- **Format Lua** (stylua, config in `.stylua.toml`: 160 col width, 2-space
  indent, single quotes preferred, no parens on single-arg calls):
  ```sh
  stylua .
  ```
- **Plugin management**: `:Lazy` inside Neovim (sync/update/health). Installed
  plugin versions are pinned in `lazy-lock.json` — commit that file alongside
  plugin spec changes.
- **LSP servers**: managed by `mason.nvim` (`:Mason` to inspect/install).
  `mason-lspconfig`'s `automatic_enable` is disabled — every server is
  explicitly configured and enabled by hand in `lua/plugins/lsp.lua`, so
  adding a new LSP means adding both a `vim.lsp.config(...)` block *and* a
  `vim.lsp.enable '<name>'` call there.
- There is no `:LspInfo`/`:LspLog` in this Neovim version. Use
  `:checkhealth vim.lsp`, `vim.lsp.get_clients()`, `vim.lsp.status()`, or
  `vim.lsp.log.get_filename()` to inspect LSP client/log state.

## Architecture

Entry point is `init.lua`: sets `mapleader`, requires `options` and
`autocmds`, bootstraps lazy.nvim, then loads every file under `lua/plugins/`
via `{ import = 'plugins' }`, then requires `keybinds`, `visual-substitute`,
and `snippet_editor`.

```
lua/
  options.lua        vim.opt settings only
  autocmds.lua        autocommands, filetype detection (vim.filetype.add),
                       diagnostic config, user commands (:Chcwd), and the
                       cursor/fold-position save/restore autocmds
  keybinds.lua         all keymaps, including Snacks picker/toggle bindings
                       and the run-current-file (<leader>xr) dispatch table
  visual-substitute.lua
  plugins/             one file per plugin (or tightly related plugin group);
                       each starts with a 2-line comment: what it's for, and
                       its GitHub URL — read that header before touching a
                       plugin file, it's the fastest way to get oriented
  snippet_engine.lua   "smart" snippets: treesitter- or regex-driven,
                       generate templated content from the buffer instead of
                       a fixed body (see file header for extraction kinds)
  snippet_editor.lua   :SnippetNew — interactive snippet creation (static,
                       or smart/treesitter, or smart/regex), no Lua needed
  snippet_util.lua     shared JSON I/O + override/exclude mechanism used by
                       both snippet files above
  snippets/
    vscode/<ft>.json   plain VSCode-format snippets (same format/loader as
                       friendly-snippets), plus _excluded.json which records
                       friendly-snippets triggers overridden by personal ones
    smart/<ft>.json    smart-snippet definitions consumed by snippet_engine.lua
```

### LSP configuration (`lua/plugins/lsp.lua`)

Every language server is configured via the modern `vim.lsp.config()` /
`vim.lsp.enable()` API (Neovim 0.11+) rather than nvim-lspconfig's older
setup-table pattern — this file *is* the source of truth for server
`cmd`/`filetypes`/`root_markers`/`settings`/`on_attach`, not
nvim-lspconfig's bundled defaults (those are only used implicitly by
mason-lspconfig for install names). A single `LspAttach` autocmd wires up
shared behavior (inlay hints, document-highlight on cursor hold) for every
server.

Notable non-default server: `spyglassmc_language_server`
(`@spyglassmc/language-server`, installed via Mason) provides both
`mcfunction` and `mcdoc` filetypes for Minecraft datapack editing.
`root_markers` is `{ 'pack.mcmeta', '.git' }` — datapacks don't use git, so
`pack.mcmeta` must stay first. Semantic tokens from this server are
selectively disabled per-buffer only for `mcfunction` (which has its own
syntax plugin, `mcfunction_syntax.lua`) and left on for `mcdoc` (which has
no separate highlighter and depends on them).

### Keybind conventions

- `<leader>` is space.
- Single-letter `<leader>` keys are grouped by role: `s*` = Snacks pickers
  (search/grep/files/etc), `t*` = Snacks toggles, `n*` = notifier, `x*` =
  one-off actions (run file, diffsplit toggle), `h*` = gitsigns hunk actions.
- Snacks picker/toggle bindings live in `keybinds.lua`, not in
  `plugins/snacks.lua` — that file only configures the plugin itself.
- Do not decide or silently fix keymap conflicts (e.g. a prefix key that's
  also bound standalone, shadowing a multi-key sequence). Surface conflicts
  for the user to resolve; they own keybind decisions.
