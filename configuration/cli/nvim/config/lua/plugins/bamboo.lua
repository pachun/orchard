-- Bamboo colorscheme (the editor half of osaka-jade) — bare plugin
-- declaration. Per-theme setup() and the `:colorscheme` call live in
-- ~/.config/orchard-themes/<theme>/nvim.lua. priority=1000 so the
-- plugin's highlight groups exist before any other plugin paints over
-- them.
return {
  "ribru17/bamboo.nvim",
  name = "bamboo",
  priority = 1000,
}
