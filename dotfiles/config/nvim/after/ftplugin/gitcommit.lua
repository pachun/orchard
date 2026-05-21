-- The commit-message editing aids now live in gitspine, so there is a
-- single source of truth shared with everyone who uses gitspine —
-- gitspine sources that copy itself when it opens a commit in nvim.
--
-- Load the same file here so plain `git commit` outside gitspine gets
-- the aids too. pcall keeps it a graceful no-op if gitspine isn't
-- checked out at the expected path.
pcall(dofile, vim.fn.expand("~/code/gitspine/src/gitcommit_aids.lua"))
