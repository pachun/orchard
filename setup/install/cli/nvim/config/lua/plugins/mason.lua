-- Mason aggregates the three central tool registries under lua/tools/
-- and ensures everything declared there is installed at startup.
--
-- All three categories funnel through mason-tool-installer rather than
-- splitting LSPs into mason-lspconfig.ensure_installed: tool-installer
-- exposes a synchronous `:MasonToolsInstallSync` command that the
-- headless installer (configure-nvim.sh) can block on, whereas
-- mason-lspconfig's installs are async-only and would race nvim's
-- exit. mason-lspconfig is still loaded so it translates lspconfig
-- server names (e.g. `lua_ls`) to Mason package names
-- (`lua-language-server`) for the installer; automatic_enable=false
-- because lua/plugins/lspconfig.lua handles enablement explicitly.
return {
  "williamboman/mason.nvim",
  dependencies = {
    "williamboman/mason-lspconfig.nvim",
    "WhoIsSethDaniel/mason-tool-installer.nvim",
  },
  config = function()
    require("mason").setup()
    require("mason-lspconfig").setup({ automatic_enable = false })

    local tools = {}
    vim.list_extend(tools, vim.tbl_keys(require("tools.language_servers")))
    vim.list_extend(tools, vim.tbl_keys(require("tools.formatters")))
    vim.list_extend(tools, vim.tbl_keys(require("tools.linters")))
    require("mason-tool-installer").setup({ ensure_installed = tools })
  end,
}
