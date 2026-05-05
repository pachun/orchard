-- Autocmds. Currently just one: rename the surrounding tmux window to
-- the basename of nvim's cwd so the window label tracks which project
-- you're in. On exit, hand control back to tmux's automatic-rename so
-- the next command (`zsh`, `git log`, whatever) labels itself.
if vim.fn.exists("$TMUX") == 1 then
  local function rename_tmux_window()
    local cwd = vim.fn.fnamemodify(vim.fn.getcwd(), ":t")
    vim.fn.system('tmux rename-window "' .. cwd .. '"')
  end

  rename_tmux_window()
  vim.api.nvim_create_autocmd("DirChanged", { callback = rename_tmux_window })
  vim.api.nvim_create_autocmd("VimLeavePre", {
    callback = function()
      vim.fn.system("tmux set-window-option automatic-rename on")
    end,
  })
end
