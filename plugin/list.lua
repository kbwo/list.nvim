if vim.g.loaded_list_nvim then
  return
end
vim.g.loaded_list_nvim = true

-- Set up auto-continuation for markdown files
vim.api.nvim_create_autocmd("FileType", {
  pattern = "markdown",
  callback = function()
    -- Insert mode: continue list on Enter
    vim.keymap.set("i", "<CR>", function()
      require("list").auto_continue_list()
    end, { buffer = true, silent = true })

    -- Normal mode: continue list on 'o' (open below)
    vim.keymap.set("n", "o", function()
      require("list").open_below_with_list()
    end, { buffer = true, silent = true })

    -- Normal mode: continue list on 'O' (open above)
    vim.keymap.set("n", "O", function()
      require("list").open_above_with_list()
    end, { buffer = true, silent = true })
  end,
})
