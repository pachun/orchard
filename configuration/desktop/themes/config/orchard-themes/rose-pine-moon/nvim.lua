-- Rosé Pine Moon (the mid-dark variant). Same plugin as rose-pine-dawn,
-- different variant; the plugin's `moon` styles are the dark set.
require("rose-pine").setup({
	variant = "moon",
	dim_inactive_windows = false,
	disable_background = require("theme_opacity").transparent(),
})
vim.opt.background = "dark"
vim.cmd.colorscheme("rose-pine")
