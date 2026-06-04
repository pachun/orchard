-- Catppuccin colorscheme — bare plugin declaration. Per-variant
-- setup() (flavour, transparent_background, etc.) and the
-- `:colorscheme` call both live in the active theme partial under
-- ~/.config/orchard-themes/<theme>/nvim.lua, which init.lua
-- sources after lazy.setup completes (and set-theme re-sources on
-- swap). priority=1000 ensures the plugin loads early so its
-- highlight groups exist before any other plugin paints over them.
return {
  "catppuccin/nvim",
  name = "catppuccin",
  priority = 1000,
}
