-- Reads lua/tools/formatters.lua, inverts the formatter→filetypes map
-- into conform's expected filetype→formatters shape, and wires up
-- format-on-save. With the table empty conform loads silently and does
-- nothing until tools are added.
--
-- When a filetype has several formatters, only the first available one
-- runs. biome is ordered ahead of prettier and only counts as available
-- inside a project with a biome.json, so a biome project formats with
-- biome and everything else falls through to prettier.
return {
  "stevearc/conform.nvim",
  event = { "BufWritePre" },
  config = function()
    local project_config_scoped_first = { biome = 1, prettier = 2 }

    local function runs_earlier(formatter, other)
      local rank = project_config_scoped_first[formatter] or math.huge
      local other_rank = project_config_scoped_first[other] or math.huge
      return rank < other_rank
    end

    local by_ft = {}
    for formatter, filetypes in pairs(require("tools.formatters")) do
      for _, ft in ipairs(filetypes) do
        by_ft[ft] = by_ft[ft] or {}
        table.insert(by_ft[ft], formatter)
      end
    end
    for _, formatters in pairs(by_ft) do
      table.sort(formatters, runs_earlier)
      formatters.stop_after_first = true
    end

    require("conform").setup({
      formatters_by_ft = by_ft,
      formatters = {
        biome = {
          require_cwd = true,
          args = { "check", "--write", "--stdin-file-path", "$FILENAME" },
        },
      },
      format_on_save = { timeout_ms = 1000, lsp_format = "fallback" },
    })
  end,
}
