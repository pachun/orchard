-- Reads lua/tools/formatters.lua, inverts the formatter→filetypes map
-- into conform's expected filetype→formatters shape, and wires up
-- format-on-save. With the table empty conform loads silently and does
-- nothing until tools are added.
return {
    "stevearc/conform.nvim",
    event = { "BufWritePre" },
    config = function()
        local by_ft = {}
        for formatter, filetypes in pairs(require("tools.formatters")) do
            for _, ft in ipairs(filetypes) do
                by_ft[ft] = by_ft[ft] or {}
                table.insert(by_ft[ft], formatter)
            end
        end

        require("conform").setup({
            formatters_by_ft = by_ft,
            format_on_save = { timeout_ms = 1000, lsp_format = "fallback" },
        })
    end,
}
