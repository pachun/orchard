-- Set <leader> before lazy.nvim loads. Plugin specs that declare keymaps
-- via `keys = { "<leader>x" }` resolve the leader at load time, so a late
-- assignment leaves them bound to the default `\` instead of space.
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- Bootstrap lazy.nvim. Clones it on first run if missing, then prepends
-- it to the runtimepath so `require("lazy")` resolves below.
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local out = vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "--branch=stable",
    "https://github.com/folke/lazy.nvim.git",
    lazypath,
  })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

-- Loads every spec under lua/plugins/. Add new plugins by dropping a
-- file in there that returns a lazy.nvim spec table.
require("lazy").setup("plugins")

-- Hybrid line numbers: absolute on the cursor line, relative on every
-- other line — gives `5j`/`12k` distance counts at a glance without
-- losing the real line number when you need it (jumping to errors,
-- copying refs, etc.).
vim.opt.number = true
vim.opt.relativenumber = true

-- Indentation: 2 spaces, no real tabs. Default nvim is 8-column hard
-- tabs, which makes auto-indent dump a wall of whitespace on every
-- newline in TS/JS/etc. nvim 0.10+ honors `.editorconfig` and LSP
-- formatter settings on top of these, so per-project overrides still
-- win for projects that pin a different width.
vim.opt.expandtab = true
vim.opt.shiftwidth = 2
vim.opt.softtabstop = 2
vim.opt.tabstop = 2

-- 1-cell sign column for the diagnostic markers below. "yes:1" keeps
-- the gutter reserved permanently so it doesn't shift when signs come
-- and go.
vim.opt.signcolumn = "yes:1"

-- Minimum width of the line number column. Default 4 leaves a wad of
-- empty space to the left of short line numbers ("   1" rather than "1").
-- 2 is enough room for a 2-digit relative number — nvim auto-expands if
-- the absolute number outgrows it on bigger files.
vim.opt.numberwidth = 2

-- Hide the "~" markers that vim draws on every line past end-of-file.
-- Default fillchars eob="~" — purely decorative, no functional value.
-- Setting to space makes those lines render blank.
vim.opt.fillchars:append({ eob = " " })

-- Diagnostics: a single dot in the gutter on lines with any kind of
-- diagnostic (color indicates severity). No inline message and no
-- underline — <leader>d pops the full text on demand.
vim.diagnostic.config({
  virtual_text = false,
  underline = false,
  update_in_insert = false,
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = "●",
      [vim.diagnostic.severity.WARN] = "●",
      [vim.diagnostic.severity.INFO] = "●",
      [vim.diagnostic.severity.HINT] = "●",
    },
  },
  float = {
    border = "rounded",
    header = "",
  },
})

-- All keymaps live in lua/keymaps.lua so there's one place to look.
require("keymaps")
