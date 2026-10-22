-- Aether colorscheme (the editor half of event-horizon) — bare plugin
-- declaration. Per-theme setup() with the palette and the `:colorscheme`
-- call live in ~/.config/orchard-themes/<theme>/nvim.lua. priority=1000 so
-- the plugin's highlight groups exist before any other plugin paints over
-- them. The v2 branch is the one whose setup() takes a colors table.
return {
  "bjarneo/aether.nvim",
  branch = "v2",
  name = "aether",
  priority = 1000,
}
