-- Gruvbox Dark. The plugin picks dark or light from vim's background
-- option, so that is set before the colorscheme loads.
vim.opt.background = "dark"
require("gruvbox").setup({
	transparent_mode = require("theme_opacity").transparent(),
})
vim.cmd.colorscheme("gruvbox")
