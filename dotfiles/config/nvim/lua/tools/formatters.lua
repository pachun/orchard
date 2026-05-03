-- Formatters to install via Mason and run via conform.nvim. Keys are
-- Mason package names (which usually match the conform formatter name
-- — `:Mason` tab 5 lists them); values are the filetypes to run
-- against. conform expects ft → list-of-formatters, so the plugin spec
-- inverts this on setup.
--
-- Example:
--   prettier = { "javascript", "typescript", "json", "yaml" },
--   stylua   = { "lua" },
return {}
