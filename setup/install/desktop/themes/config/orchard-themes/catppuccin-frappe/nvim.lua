require("catppuccin").setup({
  flavour = "frappe",
  transparent_background = require("theme_opacity").transparent(),
})
vim.opt.background = "dark"
vim.cmd.colorscheme("catppuccin-frappe")
