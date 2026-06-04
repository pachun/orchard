-- Bridge between nvim-tree and the LSP. When you rename or move a file
-- in the tree, this fires `workspace/willRenameFiles` so the LSP can
-- update every import path referencing the old name. Without it, file
-- renames silently leave broken imports across the project.
return {
  "antosha417/nvim-lsp-file-operations",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-tree/nvim-tree.lua",
  },
  config = true,
}
