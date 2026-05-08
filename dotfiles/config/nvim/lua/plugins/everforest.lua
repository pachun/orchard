-- Everforest colorscheme (lua port). Setup runs eagerly; the active
-- theme partial under ~/.config/orchard-themes/<theme>/nvim.lua does
-- the `:colorscheme` call. background = "hard" matches ghostty's
-- "Everforest Dark Hard" so terminal + nvim stay visually aligned.
return {
  "neanias/everforest-nvim",
  name = "everforest",
  priority = 1000,
  config = function()
    require("everforest").setup({
      background = "hard",
    })
  end,
}