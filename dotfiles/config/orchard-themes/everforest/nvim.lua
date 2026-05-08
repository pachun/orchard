-- everforest's transparent_background_level: 0=opaque, 2=fully
-- transparent (the equivalent of catppuccin's transparent_background = true).
require("everforest").setup({
	transparent_background_level = require("theme_opacity").transparent() and 2 or 0,
})
vim.opt.background = "dark"
vim.cmd.colorscheme("everforest")
