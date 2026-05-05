-- Tim Pope's git plugin. Used here primarily for `:Git diff` — a
-- syntax-highlighted unified diff buffer (GitX-style). Other useful
-- entry points:
--   :Git              — status window with stage/unstage hotkeys (g?)
--   :Git diff         — unified diff of working tree vs index
--   :Git diff HEAD    — diff vs last commit
--   :Git blame        — inline blame buffer; press `o` on a line for the commit
--   :Git log          — log in a buffer
--   :Gedit HEAD~1:%   — open a previous version of the current file
return {
  "tpope/vim-fugitive",
  cmd = { "Git", "Gedit", "Gdiffsplit", "Gvdiffsplit", "Gread", "Gwrite", "GBrowse" },
}
