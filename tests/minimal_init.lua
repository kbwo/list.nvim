-- Minimal init.lua for testing with plenary

local plenary_dir = os.getenv("PLENARY_DIR") or "/tmp/plenary.nvim"
local plugin_dir = vim.fn.fnamemodify(vim.fn.resolve(debug.getinfo(1, "S").source:sub(2)), ":p:h:h")

vim.opt.rtp:append(plenary_dir)
vim.opt.rtp:append(plugin_dir)

vim.cmd("runtime! plugin/plenary.vim")
vim.cmd("runtime! plugin/list.lua")
