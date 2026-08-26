-- Monokai Pro colorscheme (ristretto and the other filters) — bare
-- plugin declaration. Per-theme setup() and the `:colorscheme` call
-- live in ~/.config/orchard-themes/<theme>/nvim.lua. priority=1000 so
-- the plugin's highlight groups exist before any other plugin paints
-- over them.
return {
  "loctvl842/monokai-pro.nvim",
  name = "monokai-pro",
  priority = 1000,
}
