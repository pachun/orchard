-- Reads lua/tools/linters.lua, inverts the linter→filetypes map into
-- nvim-lint's expected filetype→linters shape, and triggers a lint on
-- write + buffer enter. With the table empty no autocmds run anything.
return {
  "mfussenegger/nvim-lint",
  event = { "BufReadPre", "BufNewFile" },
  config = function()
    local by_ft = {}
    for linter, filetypes in pairs(require("tools.linters")) do
      for _, ft in ipairs(filetypes) do
        by_ft[ft] = by_ft[ft] or {}
        table.insert(by_ft[ft], linter)
      end
    end

    require("lint").linters_by_ft = by_ft

    vim.api.nvim_create_autocmd({ "BufWritePost", "BufReadPost", "InsertLeave" }, {
      callback = function()
        require("lint").try_lint()
      end,
    })
  end,
}
