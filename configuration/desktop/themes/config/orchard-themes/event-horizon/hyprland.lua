-- Window border colors for Event Horizon. Loaded by the main hyprland.lua
-- through the orchard-themes/active symlink, so a set-theme switch
-- repaints borders to match. Active = the theme's horizon gradient, cyan
-- into blue into green at 45 degrees, as upstream ships it; inactive = the
-- same cyan at a third opacity, which recedes against the base. Border
-- width itself lives in the main config's general block.
--
-- The terminal is translucent in this theme (ghostty.conf), and the
-- wallpaper's neon ring makes text unreadable through plain glass, so
-- the blur behind translucent windows is upstream's: four tight passes
-- and the blurred field darkened to 30%. Themes with opaque terminals
-- never show the blur, so this is the one place it belongs. The terminal
-- has to ask for the blur as well; ghostty.conf does that through
-- gtk-custom-css (see ghostty/config/blur-behind-window.css for why).
local horizonGradient = {
	colors = { "rgb(59e1e3)", "rgb(59e1e3)", "rgb(26bbd9)", "rgb(26bbd9)", "rgb(29d398)", "rgb(29d398)" },
	angle = 45,
}
hl.config({
	general = { col = { active_border = horizonGradient, inactive_border = "rgba(59e1e355)" } },
	decoration = {
		blur = {
			enabled = true,
			size = 3,
			passes = 4,
			noise = 0.02,
			contrast = 0.85,
			brightness = 0.55,
			vibrancy = 0.06,
			vibrancy_darkness = 0.70,
			ignore_opacity = true,
		},
	},
})
