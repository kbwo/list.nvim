# Development Guide

## Prerequisites

- Neovim >= 0.9.0
- [lua-language-server](https://github.com/LuaLS/lua-language-server) (for linting)
- [stylua](https://github.com/JohnnyMorganz/StyLua) (for formatting)

## Installation

Install development dependencies:

```bash
# Install lua-language-server
wget -qO- https://github.com/LuaLS/lua-language-server/releases/latest/download/lua-language-server-3.7.4-linux-x64.tar.gz | tar -xz -C /tmp
sudo mv /tmp/bin/lua-language-server /usr/local/bin/

# Install stylua
wget -qO- https://github.com/JohnnyMorganz/StyLua/releases/latest/download/stylua-linux-x86_64.zip | funzip > stylua
chmod +x stylua
sudo mv stylua /usr/local/bin/
```

## Running Tests

Tests use [plenary.nvim](https://github.com/nvim-lua/plenary.nvim) and are automatically installed when running tests.

```bash
# Run all tests
make test

# Run linting
make lint

# Format code
make format

# Check formatting (CI-friendly)
make check

# Run all CI checks
make ci
```

## Project Structure

```
.
├── lua/
│   └── list/
│       └── init.lua          # Main plugin code
├── plugin/
│   └── list.lua              # Plugin entry point
├── tests/
│   ├── minimal_init.lua      # Minimal init for testing
│   └── list_spec.lua         # Test specs
├── scripts/
│   └── test.sh               # Test runner script
├── .github/
│   └── workflows/
│       └── ci.yml            # GitHub Actions CI
├── .stylua.toml              # Stylua configuration
├── .luarc.json               # Lua language server configuration
├── .editorconfig             # Editor configuration
└── Makefile                  # Development tasks
```

## Writing Tests

Tests are written using plenary.nvim's test framework. Example:

```lua
describe("my feature", function()
  it("works correctly", function()
    assert.equals(1 + 1, 2)
  end)
end)
```

Add your test files to `tests/` with the `_spec.lua` suffix.

## CI/CD

GitHub Actions runs on every push and pull request:
- Lint check with lua-language-server
- Format check with stylua
- Tests on Ubuntu and macOS
- Tests with Neovim stable and nightly
