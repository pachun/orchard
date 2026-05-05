-- Toggle-comment with C-/. The ts-context-commentstring dep makes the
-- comment style match the language *at the cursor* rather than the
-- whole file's filetype — so commenting a line inside a JSX expression
-- gets `{/* ... */}`, while a line of plain JS in the same file gets
-- `// ...`.
return {
  "numToStr/Comment.nvim",
  dependencies = { "JoosepAlviste/nvim-ts-context-commentstring" },
  config = function()
    require("Comment").setup({
      pre_hook = require("ts_context_commentstring.integrations.comment_nvim").create_pre_hook(),
    })
  end,
}
