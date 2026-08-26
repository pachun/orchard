vim.opt.background = "dark"
vim.cmd.colorscheme("hackerman")
-- hackerman.nvim has no transparency option; clear the surfaces by hand
-- so the terminal shows through like it does for the other themes.
if require("theme_opacity").transparent() then
	for _, group in ipairs({ "Normal", "NormalNC", "NormalFloat", "SignColumn", "LineNr" }) do
		vim.api.nvim_set_hl(0, group, { bg = "none" })
	end
end
