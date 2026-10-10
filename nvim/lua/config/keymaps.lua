-- <leader>cf  — copy the current filename to clipboard
vim.keymap.set("n", "<leader>cf", function()
  local f = vim.fn.expand("%:t")
  vim.fn.setreg("+", f)
  vim.notify("Copied filename: " .. f)
end, { desc = "Copy Filename" })

-- <leader>cp  — copy the current relative path to clipboard
vim.keymap.set("n", "<leader>cp", function()
  local p = vim.fn.expand("%")
  vim.fn.setreg("+", p)
  vim.notify("Copied path: " .. p)
end, { desc = "Copy Relative Path" })
