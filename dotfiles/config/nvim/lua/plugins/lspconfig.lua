-- Reads lua/tools/language_servers.lua and registers each entry via
-- the native nvim 0.11+ LSP API (vim.lsp.config + vim.lsp.enable).
-- nvim-lspconfig is still a dependency because it ships per-server
-- defaults at runtime (its `lsp/<name>.lua` files); vim.lsp.config
-- overlays our overrides on top of those.
return {
  "neovim/nvim-lspconfig",
  config = function()
    -- Advertise nvim-cmp's expanded completion capabilities to every
    -- LSP. Without this, servers send the bare-bones default set and
    -- richer features (snippets, resolve, etc.) silently no-op. pcall
    -- guards the case where cmp isn't installed yet (first headless
    -- bootstrap before Lazy syncs).
    local ok, cmp_lsp = pcall(require, "cmp_nvim_lsp")
    if ok then
      vim.lsp.config("*", { capabilities = cmp_lsp.default_capabilities() })
    end

    local servers = require("tools.language_servers")
    for name, opts in pairs(servers) do
      vim.lsp.config(name, opts)
    end
    vim.lsp.enable(vim.tbl_keys(servers))
  end,
}
