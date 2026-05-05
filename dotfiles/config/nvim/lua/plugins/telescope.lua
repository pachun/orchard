-- Fuzzy picker for files, buffers, grep results, LSP symbols, etc.
-- Backbone of <leader>f* keymaps (see lua/keymaps.lua). Live-grep needs
-- ripgrep installed at the system level (pacman.txt).
return {
  "nvim-telescope/telescope.nvim",
  version = "*",
  dependencies = { "nvim-lua/plenary.nvim" },
  config = function()
    local telescope = require("telescope")
    local actions = require("telescope.actions")

    telescope.setup({
      defaults = {
        -- Show "parent/filename" instead of the full path — short enough
        -- to read in the picker, distinguishable when two files share a
        -- name (e.g. index.ts under different folders).
        path_display = function(_, path)
          local filename = vim.fn.fnamemodify(path, ":t")
          local parent_directory = vim.fn.fnamemodify(path, ":h:t")
          return parent_directory .. "/" .. filename
        end,
        mappings = {
          i = {
            ["<C-k>"] = actions.move_selection_previous,
            ["<C-j>"] = actions.move_selection_next,
          },
        },
      },
    })
  end,
}
