-- Window border colors for Hackerman. Loaded by the main hyprland.lua
-- through the orchard-themes/active symlink, so a set-theme switch
-- repaints borders to match. Active = the accent; inactive = the
-- selection color, which recedes against the base. Border width itself
-- lives in the main config's general block.
hl.config({ general = { col = { active_border = "rgb(82fb9c)", inactive_border = "rgb(1f253a)" } } })
