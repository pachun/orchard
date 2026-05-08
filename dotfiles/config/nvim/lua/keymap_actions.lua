-- Actions for lua/keymaps.lua. The shape of this table mirrors the
-- shape of `keymaps` in keymaps.lua exactly — each leaf in keymaps
-- looks up its action by the same path here. Adding a keymap and
-- adding its action both happen in named slots that have to match.
--
-- Plugin-specific buffer-local actions (e.g. nvim-tree's rename in
-- on_attach) live in their own plugin spec, not here, so removing
-- the plugin doesn't leave dangling references in this module.
-- Plugins required by a global keymap (telescope, gitsigns, etc.)
-- DO appear here — if those plugins go, the matching keymap goes.
--
-- Plugin requires are inside function bodies (not at module load)
-- so this module can be required even if a plugin is mid-load.

local splits = require("splits")

local keymap_actions = {
  -- top-level singletons
  exit_insert_mode = "<Esc>",

  -- ghostty's super+v wraps clipboard text in bracketed-paste escapes,
  -- which nvim's cmdline doesn't process — paste shows garbage.
  -- <C-r>+ inserts the `+` register directly without going through
  -- bracketed paste.
  paste = "<C-r>+",

  save   = "<cmd>w<CR>",
  quit   = splits.close_split,
  rename = vim.lsp.buf.rename,
  clear_highlights = "<cmd>nohlsearch<CR>",
  show_line_diagnostics = vim.diagnostic.open_float,

  -- <C-_> is what terminals emit for Ctrl+/.
  toggle_comment = function()
    require("Comment.api").toggle.linewise.current()
  end,

  -- Reload our personal Lua modules. Plugins are intentionally not
  -- touched: re-entering lazy.setup leaves lazy in a half-torn-down
  -- state. Restart nvim if you need plugin specs reloaded.
  reload_nvim_config = function()
    local modules = { "keymaps", "keymap_actions", "autocmds", "splits", "theme_opacity" }
    for _, name in ipairs(modules) do
      package.loaded[name] = nil
      require(name)
    end
    vim.notify(
      ("reloaded %d personal module(s)"):format(#modules),
      vim.log.levels.INFO
    )
  end,

  -- jump to position
  ["goto"] = {
    -- nvim 0.11+ deprecated goto_prev/goto_next in favor of jump({count=±N}).
    previous_diagnostic = function() vim.diagnostic.jump({ count = -1 }) end,
    next_diagnostic     = function() vim.diagnostic.jump({ count =  1 }) end,
    -- gitsigns nav_hunk dead-ends at the file edges; pcall + gg/G
    -- gives the cycle wrap-around.
    previous_git_hunk = function()
      local gs = require("gitsigns")
      local ok = pcall(gs.nav_hunk, "prev")
      if not ok then
        vim.cmd("normal! G")
        gs.nav_hunk("prev")
      end
    end,
    next_git_hunk = function()
      local gs = require("gitsigns")
      local ok = pcall(gs.nav_hunk, "next")
      if not ok then
        vim.cmd("normal! gg")
        gs.nav_hunk("next")
      end
    end,
    -- gd / gr go through Telescope so single-result and many-result
    -- cases share the same UX (preview, filter). Direct
    -- vim.lsp.buf.definition is fewer keystrokes when there's exactly
    -- one match, but loses the preview affordance and the symmetry
    -- with `gr`.
    definition = function()
      require("telescope.builtin").lsp_definitions({ position_encoding = "utf-8" })
    end,
    references = function()
      require("telescope.builtin").lsp_references({ position_encoding = "utf-8" })
    end,
  },

  find = {
    files = function()
      require("telescope.builtin").find_files({ cwd_only = true, hidden = true })
    end,
    recent_files = function()
      require("telescope.builtin").oldfiles({ cwd_only = true, hidden = true })
    end,
    strings = function()
      require("telescope.builtin").live_grep({ cwd_only = true, hidden = true })
    end,
  },

  window = {
    split_vertically   = splits.vsplit,
    split_horizontally = splits.split,
    equalize           = "<C-w>=",
    rotate_forward     = "<C-w>r",
    rotate_backward    = "<C-w>R",
    toggle_zoom        = splits.toggle_zoom,
  },

  -- editor settings (what nvim does)
  toggle_editor = {
    -- nvim-cmp's popup completions read _G.cmp_enabled to decide
    -- whether to show. Toggle and announce the new state.
    dropdown_suggestions = function()
      _G.cmp_enabled = not _G.cmp_enabled
      print(_G.cmp_enabled and "dropdown suggestions enabled" or "dropdown suggestions disabled")
    end,
    -- supermaven is the implementation; "ghost edits" is what the
    -- user sees (inline AI completions rendered as ghost text).
    ghost_edits = function()
      local api = require("supermaven-nvim.api")
      if api.is_running() then
        api.stop()
        print("ghost edits stopped")
      else
        api.start()
        print("ghost edits started")
      end
    end,
  },

  -- ui views (what's visible on-screen)
  toggle = {
    files = function()
      local api = require("nvim-tree.api")
      api.tree.collapse_all()
      api.tree.toggle()
    end,
    files_at_current_file = function()
      local api = require("nvim-tree.api")
      api.tree.collapse_all()
      api.tree.toggle({ find_file = true, focus = true })
    end,
    -- Gitsigns has no built-in toggle; walk visible windows and
    -- close the blame buffer if found, open otherwise. Filetype
    -- check covers both common gitsigns naming variants.
    git_blame = function()
      for _, win in ipairs(vim.api.nvim_list_wins()) do
        local ft = vim.bo[vim.api.nvim_win_get_buf(win)].filetype
        if ft == "gitsigns.blame" or ft == "gitsigns-blame" then
          vim.api.nvim_win_close(win, false)
          return
        end
      end
      vim.cmd("Gitsigns blame")
    end,
  },

  -- sends commands to an idle tmux pane in the same cwd; see
  -- plugins/vim-test.lua for the strategy.
  run = {
    test_under_cursor = "<cmd>TestNearest<CR>",
    tests_in_file     = "<cmd>TestFile<CR>",
    all_tests         = "<cmd>TestSuite<CR>",
  },
}

return keymap_actions
