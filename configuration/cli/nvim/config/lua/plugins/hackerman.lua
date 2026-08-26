-- Hackerman colorscheme — bare plugin declaration. Per-theme setup
-- and the `:colorscheme` call live in
-- ~/.config/orchard-themes/<theme>/nvim.lua. Depends on aether.nvim,
-- which it builds on. priority=1000 so the plugin's highlight groups
-- exist before any other plugin paints over them.
return {
  "bjarneo/hackerman.nvim",
  name = "hackerman",
  dependencies = { "bjarneo/aether.nvim" },
  priority = 1000,
}
