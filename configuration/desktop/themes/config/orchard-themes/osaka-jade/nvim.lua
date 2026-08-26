-- Osaka Jade is an Omarchy palette with no colorscheme of its own;
-- Omarchy pairs it with bamboo, whose greens sit on the same jade base.
require("bamboo").setup({
	style = "multiplex",
	transparent = require("theme_opacity").transparent(),
})
vim.opt.background = "dark"
vim.cmd.colorscheme("bamboo")
