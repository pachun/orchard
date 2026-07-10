-- Treesitter-based syntax highlighting + parsing. The default vim regex
-- highlighter falls apart on bigger TypeScript / JSX files; treesitter
-- builds an actual AST per buffer so highlights stay accurate even with
-- nested template literals, JSX, generics, etc.
--
-- branch="main" is the modern (post-rewrite) plugin. The older master
-- branch used `ensure_installed` and `highlight = { enable = true }`;
-- main moves both to explicit calls (see config below).
return {
  "nvim-treesitter/nvim-treesitter",
  branch = "main",
  lazy = false,
  build = ":TSUpdate",
  config = function()
    -- Parser installs happen out-of-band via configure-nvim.sh (see
    -- configuration/configure-nvim.sh). Calling install() from this
    -- config block would re-trigger downloads on every nvim startup,
    -- spamming :messages with download-progress lines.
    --
    -- Start treesitter highlighting whenever a buffer's filetype is
    -- detected. pcall swallows the error for filetypes without an
    -- installed parser (e.g. one added to the parser list but not yet
    -- pulled by configure-nvim.sh).
    vim.api.nvim_create_autocmd("FileType", {
      pattern = "*",
      callback = function()
        pcall(vim.treesitter.start)
      end,
    })
  end,
}
