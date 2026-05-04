-- Single source of truth for keymaps. Plugin-specific keymaps live here
-- too (rather than in lazy spec `keys = {}` blocks) so this file answers
-- "what does <leader>X do?" without grepping the plugin tree.

-- exit insert mode
vim.keymap.set("i", "jj", "<Esc>")

-- diagnostics / LSP
vim.keymap.set("n", "<leader>d", vim.diagnostic.open_float, { desc = "show line diagnostics" })
vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, { desc = "rename symbol (LSP)" })
-- Override vim's default `gd` (which does a literal search for the word
-- under the cursor and turns hlsearch on as a side effect) with the LSP
-- go-to-definition. No more leftover highlighting after jumping.
vim.keymap.set("n", "gd", vim.lsp.buf.definition, { desc = "goto definition (LSP)" })

-- search
vim.keymap.set("n", "<leader>nh", "<cmd>nohlsearch<CR>", { desc = "clear search highlights" })

-- file explorer
vim.keymap.set("n", "<leader>ee", function()
  local api = require("nvim-tree.api")
  api.tree.collapse_all()
  api.tree.toggle()
end, { desc = "toggle file explorer" })

vim.keymap.set("n", "<leader>ef", function()
  local api = require("nvim-tree.api")
  api.tree.collapse_all()
  api.tree.toggle({ find_file = true, focus = true })
end, { desc = "file explorer on current file" })
