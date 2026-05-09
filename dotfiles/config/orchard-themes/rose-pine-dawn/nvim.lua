-- Rosé Pine Dawn (the light variant). The plugin's `dawn` styles
-- are deliberately low-contrast to match its paper-cream base, so
-- syntax colors read soft rather than punchy.
require("rose-pine").setup({
	variant = "dawn",
	dim_inactive_windows = false,
	disable_background = require("theme_opacity").transparent(),
})
vim.opt.background = "light"
vim.cmd.colorscheme("rose-pine")
