-- Supermaven: inline AI completion (ghost-text suggestions in insert
-- mode, accept with Tab). Free tier is generous; Pro is paid.
--
-- First-run requires sign-in — can't be automated by install.sh.
-- After this plugin loads (lazy.nvim installs it on next nvim launch):
--   1. In nvim, run `:SupermavenUseFree` (or `:SupermavenUsePro`).
--   2. Browser opens for OAuth; complete the flow.
--   3. Token persists in ~/.local/share/supermaven/. Subsequent nvim
--      launches just work.
--
-- Toggle on/off mid-session via <leader>sm (see lua/keymaps.lua).
return {
  "supermaven-inc/supermaven-nvim",
  config = true,
}
