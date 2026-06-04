-- render-markdown.nvim — visual rendering of markdown inline in
-- the buffer while you read or edit. Headings get colored / iconed
-- bands; code blocks get a tinted background; tables get drawn
-- borders; `[ ]` / `[x]` checkboxes become real glyphs. Underlying
-- source is unchanged, so all vim motions, search, folds, and
-- treesitter queries operate on the actual markdown text.
--
-- Lazy-loads on filetype only — zero cost when you're editing code.
-- The `markdown` and `markdown_inline` treesitter parsers are
-- already in tools/treesitter_parsers.lua; web-devicons rides in
-- via the lualine spec.
return {
  "MeanderingProgrammer/render-markdown.nvim",
  ft = { "markdown" },
  dependencies = {
    "nvim-treesitter/nvim-treesitter",
    "nvim-tree/nvim-web-devicons",
  },
  opts = {},
}
