-- Catppuccin Frappé colorscheme — matches the rest of the system
-- (waybar / GTK / Kvantum). priority=1000 ensures it loads before any
-- plugin that paints highlight groups.
return {
  "catppuccin/nvim",
  name = "catppuccin",
  priority = 1000,
  config = function()
    require("catppuccin").setup({
      flavour = "frappe",
    })
    vim.cmd.colorscheme("catppuccin-frappe")
  end,
}
