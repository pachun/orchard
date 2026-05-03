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

vim.keymap.set("i", "jj", "<Esc>")
