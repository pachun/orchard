-- Toggle-comment with C-/. The ts-context-commentstring dep makes the
-- comment style match the language *at the cursor* rather than the
-- whole file's filetype — so commenting a line inside a JSX expression
-- gets `{/* ... */}`, while a line of plain JS in the same file gets
-- `// ...`.
--
-- Wrap the ts_context pre_hook so we always return a usable
-- commentstring. Without the wrap, files with no treesitter parser
-- and no filetype-set commentstring fall through to nil, and
-- Comment.nvim shows a `[comment.nvim] nil` toast and no-ops. The
-- chain: treesitter context → vim.bo.commentstring → `# %s` (a
-- safe shell-comment default for unrecognised dotfiles).
return {
  "numToStr/Comment.nvim",
  dependencies = { "JoosepAlviste/nvim-ts-context-commentstring" },
  config = function()
    local ts_pre_hook = require("ts_context_commentstring.integrations.comment_nvim").create_pre_hook()
    require("Comment").setup({
      pre_hook = function(ctx)
        local cstr = ts_pre_hook(ctx)
        if cstr == nil or cstr == "" then
          cstr = vim.bo.commentstring
        end
        if cstr == nil or cstr == "" then
          cstr = "# %s"
        end
        return cstr
      end,
    })
  end,
}
