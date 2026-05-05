-- Popup completion menu. Pulls candidates from the LSP, the current
-- buffer's words, and filesystem paths.
--
-- Global toggle flag — keymaps.lua's <leader>dd flips it. cmp's
-- `enabled` callback re-reads it on every keystroke so the toggle is
-- live without restart.
_G.cmp_enabled = true

return {
  "hrsh7th/nvim-cmp",
  event = "InsertEnter",
  dependencies = {
    "hrsh7th/cmp-nvim-lsp",
    "hrsh7th/cmp-buffer",
    "hrsh7th/cmp-path",
  },
  config = function()
    local cmp = require("cmp")
    -- SelectBehavior.Select highlights the candidate without inserting
    -- it into the buffer until <C-l> confirms — keeps the buffer text
    -- stable while you scan the menu.
    local select_only = { behavior = cmp.SelectBehavior.Select }

    cmp.setup({
      enabled = function()
        return _G.cmp_enabled
      end,
      -- Suppress the default `completeopt = "menuone,noinsert,noselect"`
      -- so cmp manages the menu lifecycle itself.
      completion = { completeopt = "" },
      mapping = {
        ["<C-j>"] = cmp.mapping.select_next_item(select_only),
        ["<C-k>"] = cmp.mapping.select_prev_item(select_only),
        ["<C-l>"] = cmp.mapping.confirm(),
        ["<C-h>"] = cmp.mapping.abort(),
      },
      -- Order determines priority in the menu.
      sources = {
        { name = "nvim_lsp" },
        { name = "buffer" },
        { name = "path" },
      },
    })
  end,
}
