-- Catppuccin colorscheme. Setup runs eagerly (priority=1000, no
-- lazy=true) so the highlight groups exist before any other plugin
-- paints over them. The actual `:colorscheme` call lives in the
-- per-theme partial under ~/.config/orchard-themes/<theme>/nvim.lua,
-- which init.lua sources after lazy.setup completes — so the same
-- plugin can serve any catppuccin variant the active theme picks.
return {
  "catppuccin/nvim",
  name = "catppuccin",
  priority = 1000,
  config = function()
    require("catppuccin").setup({
      flavour = "frappe",
    })
  end,
}
