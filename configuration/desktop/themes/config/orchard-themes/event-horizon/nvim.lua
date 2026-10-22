-- Event Horizon has no colorscheme of its own; upstream pairs it with
-- aether, fed the Horizon Terminal Dark roles from its neovim.lua.
require("aether").setup({
	transparent = require("theme_opacity").transparent(),
	colors = {
		bg = "#1c1e26",
		bg_dark = "#15171d",
		bg_highlight = "#2e303e",
		fg = "#cbced0",
		fg_dark = "#9da0a2",
		comment = "#6f6f70",
		red = "#e95678",
		orange = "#ec6a88",
		yellow = "#fac29a",
		green = "#29d398",
		cyan = "#59e1e3",
		blue = "#26bbd9",
		purple = "#ee64ac",
		magenta = "#f075b5",
	},
})
vim.opt.background = "dark"
vim.cmd.colorscheme("aether")
