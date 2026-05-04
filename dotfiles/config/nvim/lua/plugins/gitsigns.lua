-- Inline git status: adds +/~/_ marks in the sign column for added,
-- changed, and deleted lines vs the index. Also powers ]c / [c to
-- jump between hunks if those mappings get added later.
return {
  "lewis6991/gitsigns.nvim",
  opts = {},
}
