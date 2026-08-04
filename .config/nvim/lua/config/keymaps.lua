-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
local map = vim.keymap.set

map("n", "<leader>vb", function()
  os.execute("paplay " .. vim.env.HOME .. "/Audio/vine-boom.mp3 &")
end, { desc = "Vine Boom" })
map("n", "<leader>fml", "<cmd>CellularAutomaton make_it_rain<CR>")
map("n", "<leader>t", function()
  Snacks.terminal.toggle(nil, { win = { position = "bottom" } })
end, { desc = "Toggle terminal below" })
map("n", "<F2>", vim.lsp.buf.rename, { desc = "Rename symbol" })
map("n", "<F3>", vim.lsp.buf.code_action, { desc = "Code actions" })
