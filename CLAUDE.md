# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Neovim plugin for list manipulation in markdown/text files. The plugin will support:
- Multiple list formats: ordered lists, bullet lists (`-` or `*`), and checklists
- Auto-continuation of list formatting on new lines (preserving indent)
- Toggling checkboxes
- Cycling list types for sibling elements: `-` → `*` → `1.` → `[ ]`
- Cycling all list types within a contiguous list block

## Architecture

### Plugin Structure (Standard Neovim Plugin Layout)

- `lua/list/init.lua` - Main module with all plugin logic. Exports a table with `setup()` and feature functions
- `plugin/list.lua` - Plugin loader that runs once on Neovim startup. Sets `vim.g.loaded_list_nvim` guard, registers user commands
- `tests/*_spec.lua` - Test files using plenary.nvim's busted-style framework
- `tests/minimal_init.lua` - Minimal Neovim config that loads plenary and this plugin for testing

### Testing Architecture

Uses **plenary.nvim** (auto-downloaded to `/tmp/plenary.nvim` on first run):
- Tests use `describe()` / `it()` blocks (busted-style)
- Use standard Lua assertions: `assert(condition)`, `assert(x == y)`, `assert(type(x) == "function")`
- **Important**: Avoid plenary-specific assertions like `assert.is_not_nil()` or `assert.is_function()` - lua-language-server doesn't recognize these and will show undefined-field warnings
- `tests/minimal_init.lua` sets up runtime path and loads both plenary and the plugin

## Development Commands

### Essential Commands
```bash
make test      # Run all tests (*_spec.lua files)
make lint      # Run lua-language-server --check .
make format    # Auto-format with stylua
make check     # Verify formatting (CI mode, non-destructive)
make ci        # Run all checks: format check + lint + test
```

### Running Single Test
```bash
# Run specific test file
nvim --headless --noplugin -u tests/minimal_init.lua \
  -c "PlenaryBustedFile tests/list_spec.lua"
```

### Test Script
`scripts/test.sh` handles plenary installation and test execution. Can override plenary location with `PLENARY_DIR` env var.

## Code Quality Tools

### Linting: lua-language-server
- Config: `.luarc.json`
- Runtime: LuaJIT with Neovim's Lua path
- Global: `vim` (Neovim API)
- Libraries: luv, busted (for test globals like `describe`, `it`, `assert`)
- Runs via: `lua-language-server --check .`

### Formatting: stylua
- Config: `.stylua.toml`
- Settings: 100 char width, 2-space indent, Unix line endings, auto-prefer double quotes
- Targets: `lua/`, `tests/`, `plugin/`

## Important Conventions

### README.md is Sacred
**NEVER modify README.md**. It contains the original Japanese feature specification. If documentation changes are needed, put them in `docs/` directory.

### File Organization
- Plugin code: `lua/list/` (can add more modules as `lua/list/submodule.lua`)
- Entry point: `plugin/list.lua` (user commands, autocommands, keymaps)
- Documentation: `docs/` for development guides (never README.md)
- Tests: `tests/` with `*_spec.lua` suffix

### Neovim API Patterns
- Use `vim.api.nvim_*` functions for buffer/window operations
- `vim.opt` for option setting, `vim.g` for global variables
- User commands via `vim.api.nvim_create_user_command()`
- Autocommands via `vim.api.nvim_create_autocmd()`

## CI Pipeline

GitHub Actions runs on push/PR:
1. **Lint job**: Install lua-language-server → `make lint`
2. **Format job**: Install stylua → `make check`
3. **Test job**: Matrix (Ubuntu/macOS × stable/nightly Neovim) → Install Neovim → `make test`
