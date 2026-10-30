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
local function upstream_config(server_name)
  local path = vim.api.nvim_get_runtime_file("lsp/" .. server_name .. ".lua", false)[1]
  return dofile(path)
end

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
  -- ts_ls only attaches when the project's TypeScript still ships
  -- tsserver.js (versions before 7); otherwise its initialize request
  -- fails with an error popup and tsc below serves the project.
  -- Auto-imports use the project's path aliases (tsconfig paths or
  -- package.json imports) instead of ../../ relative specifiers.
  ts_ls = {
    init_options = {
      preferences = { importModuleSpecifierPreference = "non-relative" },
    },
    on_attach = function(client, _)
      client.server_capabilities.documentFormattingProvider = false
    end,
    root_dir = function(bufnr, on_dir)
      upstream_config("ts_ls").root_dir(bufnr, function(root)
        local tsserver = vim.fs.joinpath(root, "node_modules/typescript/lib/tsserver.js")
        if vim.uv.fs_stat(tsserver) then
          on_dir(root)
        end
      end)
    end,
  },

  -- TypeScript 7+ (the native compiler) ships its language server as
  -- `tsc --lsp` and no longer includes the tsserver.js that ts_ls
  -- wraps. lspconfig's tsc config attaches only when the project's
  -- node_modules/.bin/tsc is version 7 or newer, so ts_ls keeps
  -- serving older projects and this serves the new ones.
  -- tsc never asks the editor to re-check a file's dependents after
  -- another file changes, so a type edited in one buffer left stale
  -- errors in every other open buffer until a manual :LspRestart.
  -- Saving any buffer now re-pulls diagnostics for all of them.
  -- Auto-imports use the project's path aliases, as for ts_ls above;
  -- the native server reads the editor-style settings sections.
  tsc = {
    settings = {
      typescript = { preferences = { importModuleSpecifier = "non-relative" } },
      javascript = { preferences = { importModuleSpecifier = "non-relative" } },
    },
    on_attach = function(client, _)
      client.server_capabilities.documentFormattingProvider = false
      vim.api.nvim_create_autocmd("LspNotify", {
        group = vim.api.nvim_create_augroup("tsc_refresh_dependents_" .. client.id, { clear = true }),
        callback = function(event)
          if event.data.client_id == client.id and event.data.method == "textDocument/didSave" then
            vim.lsp.diagnostic.on_refresh(nil, nil, { client_id = client.id })
          end
        end,
      })
    end,
  },

  rust_analyzer = {},
}
