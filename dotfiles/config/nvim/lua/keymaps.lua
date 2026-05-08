-- Single source of truth for keymaps. Plugin-specific keymaps live here
-- too (rather than in lazy spec `keys = {}` blocks) so this file answers
-- "what does <leader>X do?" without grepping the plugin tree.

-- exit insert mode
vim.keymap.set("i", "jj", "<Esc>")

-- Paste from system clipboard in cmdline mode. ghostty's `super+v`
-- sends clipboard text wrapped in bracketed-paste escapes, which
-- nvim's cmdline (popup or default) doesn't process — so the paste
-- inserts garbage instead of the clipboard contents. <C-r>+ inserts
-- the `+` register directly without going through bracketed paste,
-- so we map cmdline <C-v> to that. Cmdline-mode-only — insert and
-- normal mode <C-v> retain their default meanings.
vim.keymap.set("c", "<C-v>", "<C-r>+", { desc = "paste from system clipboard (cmdline)" })

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

-- toggle supermaven (inline AI ghost-text completions)
vim.keymap.set("n", "<leader>sm", function()
  local api = require("supermaven-nvim.api")
  if api.is_running() then
    api.stop()
    print("Supermaven stopped")
  else
    api.start()
    print("Supermaven started")
  end
end, { desc = "toggle supermaven" })

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
-- [d / ]d — previous / next diagnostic. nvim 0.11+ deprecated
-- goto_prev / goto_next in favor of `jump({count = ±N})`.
vim.keymap.set("n", "[d", function()
  vim.diagnostic.jump({ count = -1 })
end, { desc = "previous diagnostic" })
vim.keymap.set("n", "]d", function()
  vim.diagnostic.jump({ count = 1 })
end, { desc = "next diagnostic" })

-- gd / gr — definition + references, both via Telescope so single-
-- result and many-result cases share the same UX (preview pane,
-- filter, navigation). Direct vim.lsp.buf.definition jumps in place
-- which is fewer keystrokes when there's exactly one definition,
-- but it loses the preview affordance and asymmetry with `gr`.
vim.keymap.set("n", "gd", function()
  require("telescope.builtin").lsp_definitions({ position_encoding = "utf-8" })
end, { desc = "goto definition (LSP, via telescope)" })
vim.keymap.set("n", "gr", function()
  require("telescope.builtin").lsp_references({ position_encoding = "utf-8" })
end, { desc = "goto references (LSP, via telescope)" })

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

-- git
-- Toggle full-file blame side window. Gitsigns has no built-in toggle;
-- we walk visible windows and close the blame buffer if found, open
-- otherwise. Filetype check covers both common gitsigns naming variants.
vim.keymap.set("n", "<leader>gb", function()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local ft = vim.bo[vim.api.nvim_win_get_buf(win)].filetype
    if ft == "gitsigns.blame" or ft == "gitsigns-blame" then
      vim.api.nvim_win_close(win, false)
      return
    end
  end
  vim.cmd("Gitsigns blame")
end, { desc = "toggle full-file git blame" })

-- [c / ]c — previous / next git hunk (uncommitted change). Wraps
-- around: if we're past the last hunk in the requested direction,
-- gitsigns.nav_hunk pcalls fails; fall back to gg/G then retry so
-- the cycle is continuous instead of dead-ending.
vim.keymap.set("n", "[c", function()
  local gs = require("gitsigns")
  local ok = pcall(gs.nav_hunk, "prev")
  if not ok then
    vim.cmd("normal! G")
    gs.nav_hunk("prev")
  end
end, { desc = "previous git hunk" })
vim.keymap.set("n", "]c", function()
  local gs = require("gitsigns")
  local ok = pcall(gs.nav_hunk, "next")
  if not ok then
    vim.cmd("normal! gg")
    gs.nav_hunk("next")
  end
end, { desc = "next git hunk" })

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

-- <leader>R — reload our personal Lua modules without restarting nvim.
-- Clears each from `package.loaded` and re-requires it, so edits to
-- keymaps/autocmds/splits take effect against the live session.
--
-- Plugins are intentionally not touched: re-entering `lazy.setup()` or
-- `lazy.reload()` against the running instance leaves lazy in a
-- half-torn-down state (Config.options.git nil, deactivate failures).
-- Restart nvim if you need plugin specs reloaded.
vim.keymap.set("n", "<leader>R", function()
  local modules = { "keymaps", "autocmds", "splits" }
  for _, name in ipairs(modules) do
    package.loaded[name] = nil
    require(name)
  end
  vim.notify(
    ("reloaded %d personal module(s)"):format(#modules),
    vim.log.levels.INFO
  )
end, { desc = "reload personal nvim modules" })
