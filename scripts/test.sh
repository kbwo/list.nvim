#!/usr/bin/env bash

set -e

# Install plenary.nvim if not exists
PLENARY_DIR="${PLENARY_DIR:-/tmp/plenary.nvim}"
if [ ! -d "$PLENARY_DIR" ]; then
  echo "Installing plenary.nvim to $PLENARY_DIR"
  git clone --depth 1 https://github.com/nvim-lua/plenary.nvim "$PLENARY_DIR"
fi

export PLENARY_DIR

# Run tests
echo "Running tests..."
nvim --headless --noplugin -u tests/minimal_init.lua \
  -c "PlenaryBustedDirectory tests/ { minimal_init = 'tests/minimal_init.lua' }"
