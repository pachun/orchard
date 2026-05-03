-- Language servers to install via Mason and enable via vim.lsp.enable().
-- Keys are lspconfig server names (full list at `:Mason` tab 2 or in
-- nvim-lspconfig's docs). Values are tables passed to vim.lsp.config()
-- — leave as `{}` to use the upstream default config from
-- nvim-lspconfig.
--
-- Example:
--   lua_ls = {
--     settings = {
--       Lua = {
--         diagnostics = { globals = { "vim" } },
--       },
--     },
--   },
return {
	lua_ls = {
		settings = {
			Lua = {
				-- treat `vim` as a known global so the LSP doesn't flag
				-- every `vim.opt`, `vim.keymap`, etc. as undefined
				diagnostics = { globals = { "vim" } },
				-- expand snippet placeholders on completion accept
				completion = { callSnippet = "Replace" },
			},
		},
	},
}
