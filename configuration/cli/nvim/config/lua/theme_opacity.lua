-- Parse the active orchard-theme's ghostty.conf for its
-- background-opacity. nvim's colorscheme plugins use this to mirror
-- ghostty's transparency, keeping a single source of truth (the
-- ghostty config file) for "how transparent is this theme."
--
-- ghostty has no config-file variable substitution and no API for
-- exporting its parsed value, so we just re-read the file. It's
-- tiny; the I/O cost is invisible.
local M = {}

function M.transparent()
  local path = vim.fn.expand("~/.config/orchard-themes/active/ghostty.conf")
  local f = io.open(path, "r")
  if not f then
    return false
  end
  for line in f:lines() do
    local val = line:match("^%s*background%-opacity%s*=%s*([%d.]+)")
    if val then
      f:close()
      return (tonumber(val) or 1.0) < 1.0
    end
  end
  f:close()
  return false
end

return M
