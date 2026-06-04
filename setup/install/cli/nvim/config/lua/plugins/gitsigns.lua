-- Inline git status: adds +/~/_ marks in the sign column for added,
-- changed, and deleted lines vs the index. Also powers ]c / [c to
-- jump between hunks if those mappings get added later.
return {
  "lewis6991/gitsigns.nvim",
  opts = {
    -- No +/~/_ marks in the gutter; the diagnostic dot already lives
    -- there and stacking both gets noisy. The plugin stays loaded for
    -- :Gitsigns commands, hunk navigation, and inline blame.
    signcolumn = false,
  },
}
