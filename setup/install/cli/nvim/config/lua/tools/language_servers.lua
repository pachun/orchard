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

  -- Bash language server. The default filetypes only cover `sh` and
  -- `bash`; extending to `zsh` so the same diagnostics/completion
  -- light up when editing ~/.zshrc and friends.
  bashls = {
    filetypes = { "sh", "bash", "zsh" },
  },

  -- Markdown LSP — cross-file link resolution, heading completion,
  -- diagnostics for broken refs.
  marksman = {},

  -- Elixir LSP. Mason installs the binary as `elixir-ls`; lspconfig's
  -- default cmd points at `elixir-ls.sh` (a shell wrapper), which
  -- doesn't ship with the Mason package.
  elixirls = {
    cmd = { "elixir-ls" },
  },

  -- TypeScript / JavaScript LSP. Formatting is disabled because we
  -- delegate that to prettier (added to lua/tools/formatters.lua
  -- separately); ts_ls's built-in formatter conflicts with prettier
  -- on style decisions and we don't want it racing on save.
  ts_ls = {
    on_attach = function(client, _)
      client.server_capabilities.documentFormattingProvider = false
    end,
  },

  rust_analyzer = {},
}
