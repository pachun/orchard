-- Single source of truth for keymaps. Plugin-specific keymaps live here
-- too (rather than in lazy spec `keys = {}` blocks) so this file answers
-- "what does <leader>X do?" without grepping the plugin tree.

-- exit insert mode
vim.keymap.set("i", "jj", "<Esc>")

-- save / quit
local splits = require("splits")
vim.keymap.set("n", "<leader>w", "<cmd>w<CR>", { desc = "save buffer" })
vim.keymap.set("n", "<leader>q", splits.close_split, { desc = "quit window (unzooms first if zoomed)" })

-- split management
vim.keymap.set("n", "<leader>d|", splits.vsplit, { desc = "vsplit" })
vim.keymap.set("n", "<leader>d_", splits.split, { desc = "split" })
vim.keymap.set("n", "<leader>d+", splits.toggle_zoom, { desc = "toggle zoom" })
vim.keymap.set("n", "<leader>de", "<C-w>=", { desc = "equalize splits" })
vim.keymap.set("n", "<leader>d{", "<C-w>r", { desc = "rotate splits forward" })
vim.keymap.set("n", "<leader>d}", "<C-w>R", { desc = "rotate splits backward" })

-- toggle nvim-cmp dropdown completions (the popup menu, not LSP itself)
vim.keymap.set("n", "<leader>dd", function()
  _G.cmp_enabled = not _G.cmp_enabled
  print(_G.cmp_enabled and "dropdown suggestions enabled" or "dropdown suggestions disabled")
end, { desc = "toggle dropdown suggestions" })

-- comment toggle (Ctrl+/). <C-_> is what terminals emit for Ctrl+/.
-- Pressed twice matches boo muscle memory; change to single <C-_> if
-- preferred. In visual mode we drop out to normal first, otherwise the
-- API call stays scoped to the current line.
vim.keymap.set("n", "<C-_><C-_>", function()
  require("Comment.api").toggle.linewise.current()
end, { desc = "toggle comment line" })
vim.keymap.set("v", "<C-_><C-_>", function()
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "x", false)
  require("Comment.api").toggle.linewise(vim.fn.visualmode())
end, { desc = "toggle comment block" })

-- diagnostics / LSP
vim.keymap.set("n", "<leader>d", vim.diagnostic.open_float, { desc = "show line diagnostics" })
vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, { desc = "rename symbol (LSP)" })
-- Override vim's default `gd` (which does a literal search for the word
-- under the cursor and turns hlsearch on as a side effect) with the LSP
-- go-to-definition. No more leftover highlighting after jumping.
vim.keymap.set("n", "gd", vim.lsp.buf.definition, { desc = "goto definition (LSP)" })

-- search
vim.keymap.set("n", "<leader>nh", "<cmd>nohlsearch<CR>", { desc = "clear search highlights" })

-- telescope
vim.keymap.set("n", "<leader>ff", function()
  require("telescope.builtin").find_files({ cwd_only = true, hidden = true })
end, { desc = "find files" })

vim.keymap.set("n", "<leader>fs", function()
  require("telescope.builtin").live_grep({ cwd_only = true, hidden = true })
end, { desc = "find string (live grep)" })

vim.keymap.set("n", "<leader>fr", function()
  require("telescope.builtin").oldfiles({ cwd_only = true, hidden = true })
end, { desc = "find recent files" })

-- vim-test (sends to an idle tmux pane in the same cwd; see
-- plugins/vim-test.lua for the strategy)
vim.keymap.set("n", "<leader>s", "<cmd>TestNearest<CR>", { desc = "run test under cursor" })
vim.keymap.set("n", "<leader>t", "<cmd>TestFile<CR>", { desc = "run tests in file" })
vim.keymap.set("n", "<leader>a", "<cmd>TestSuite<CR>", { desc = "run all tests" })

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
