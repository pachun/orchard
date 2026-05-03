-- Reads lua/tools/language_servers.lua and registers each entry via
-- the native nvim 0.11+ LSP API (vim.lsp.config + vim.lsp.enable).
-- nvim-lspconfig is still a dependency because it ships per-server
-- defaults at runtime (its `lsp/<name>.lua` files); vim.lsp.config
-- overlays our overrides on top of those.
return {
  "neovim/nvim-lspconfig",
  config = function()
    local servers = require("tools.language_servers")
    for name, opts in pairs(servers) do
      vim.lsp.config(name, opts)
    end
    vim.lsp.enable(vim.tbl_keys(servers))
  end,
}
