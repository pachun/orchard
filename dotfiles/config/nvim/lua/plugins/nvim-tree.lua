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
