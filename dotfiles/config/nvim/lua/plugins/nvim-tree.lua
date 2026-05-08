-- Disable netrw (nvim's built-in file browser) at the top of the spec
-- module — this runs as soon as lazy reads the file, which has to be
-- before nvim's runtime plugins fire and load netrw.
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

return {
  "nvim-tree/nvim-tree.lua",
  -- Keymaps live in lua/keymaps.lua. Without `keys`/`event`/`cmd` lazy
  -- loads the plugin at startup, which is the right trade — single
  -- index for "what does <leader>X do" beats shaving a few ms off boot.
  config = function()
    require("nvim-tree").setup({
      -- Buffer-local key adjustments. nvim-tree's default mappings
      -- collide with two things we care about:
      --   - `<C-k>` (default: toggle_file_info) shadows vim-tmux-
      --     navigator's global `<C-k>` for "go to pane above". Drop
      --     it so the navigator's mapping takes over. Pane nav lives
      --     in one place (the navigator + tmux.conf), not redefined
      --     per buffer-type.
      --   - `e` (default: fs.rename_basename) fires whenever a
      --     leader-prefixed sequence ending in 'e' (like <leader>ef)
      --     times out faster than the user finishes the sequence.
      --     The result was accidental rename prompts. Drop bare `e`
      --     and rebind file-rename to whatever chord keymaps.lua
      --     assigns to "rename" (the LSP rename) — same muscle
      --     memory, same intent ("rename"), different action per
      --     context. Reading the chord from keymaps means changing
      --     it in one place keeps both bindings in sync.
      on_attach = function(bufnr)
        local api = require("nvim-tree.api")
        api.config.mappings.default_on_attach(bufnr)
        vim.keymap.del("n", "<C-k>", { buffer = bufnr })
        vim.keymap.del("n", "e", { buffer = bufnr })

        local keymaps = require("keymaps")
        local rename_keymap_name = "rename"
        vim.keymap.set("n", keymaps[rename_keymap_name].trigger, function()
          require("nvim-tree.api").fs.rename()
        end, { buffer = bufnr, desc = rename_keymap_name })
      end,
      sort = { sorter = "case_sensitive" },
      view = { width = 30 },
      renderer = {
        group_empty = true,
        -- Show just the directory's basename as the tree title rather
        -- than the full path.
        root_folder_label = function(path)
          return vim.fn.fnamemodify(path, ":t")
        end,
      },
      filters = {
        -- mimic-generated elixir test files + macOS dotfile noise.
        custom = { "*.coverdata", ".DS_Store" },
      },
      -- Git status icons in the tree are redundant with gitsigns in the
      -- buffer gutter.
      git = { enable = false },
    })
  end,
}
