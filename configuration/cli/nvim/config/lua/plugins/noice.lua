-- noice.nvim replaces several nvim UI surfaces with floating popups:
--   - cmdline (`:` and `/`) — rendered as a centered popup near the top
--   - long messages — a scrollable side split
--   - LSP hover/signature help — treesitter-highlighted markdown
--   - LSP progress indicator (e.g. rust-analyzer indexing on startup)
--
-- Ordinary messages are *not* popups. noice's default backend for them is
-- nvim-notify, which stacks every "written", warning, and vim.notify call
-- in the top-right corner over your code for a few seconds. Instead they
-- go to the `cmdline` view: the bottom line stock vim already reserves for
-- them, where they sit until the next message or redraw and cover nothing.
-- nui.nvim is the floating-window toolkit noice draws into.
local bottomLine = "cmdline"

return {
  "folke/noice.nvim",
  event = "VeryLazy",
  dependencies = {
    "MunifTanjim/nui.nvim",
  },
  config = function()
    require("noice").setup({
      messages = {
        view = bottomLine,
        view_error = bottomLine,
        view_warn = bottomLine,
      },
      notify = { view = bottomLine },
      lsp = {
        message = { view = bottomLine },
        -- Route LSP markdown (hover docs, signature help) through noice
        -- so it gets treesitter-highlighted code blocks instead of the
        -- plain unhighlighted default. cmp.entry.get_documentation only
        -- kicks in when nvim-cmp is installed; harmless otherwise.
        override = {
          ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
          ["vim.lsp.util.stylize_markdown"] = true,
          ["cmp.entry.get_documentation"] = true,
        },
      },
      presets = {
        bottom_search = true,        -- keep `/` search at the bottom (popup feels wrong for find-as-you-type)
        command_palette = true,      -- `:` cmdline and completion menu render as one centered popup
        long_message_to_split = true, -- multi-line messages open in a scrollable split instead of pressing ENTER
        inc_rename = false,          -- only useful with smjonas/inc-rename.nvim installed
        lsp_doc_border = false,      -- flip to true if you want a rounded border around hover/signature popups
      },
      -- Suppress nvim's "5 fewer lines" / "12 more lines" status messages.
      -- These fire on every multi-line delete/paste, and "I already know
      -- what I just typed" isn't worth a line of chatter.
      routes = {
        {
          filter = {
            event = "msg_show",
            any = {
              { find = "%d+ fewer lines" },
              { find = "%d+ more lines" },
            },
          },
          opts = { skip = true },
        },
      },
    })
  end,
}
