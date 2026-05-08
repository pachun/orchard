-- Autocmds.

-- Re-apply the orchard-theme whose files you just edited. Saving any
-- file under .../orchard-themes/<name>/ (the theme partial files,
-- the ghostty.conf, etc.) fires `set-theme <name>` async, so the
-- swap propagates to ghostty + every running nvim window — including
-- this one — without you having to remember to run it. jobstart
-- (detached) keeps the save synchronous from the editor's POV; the
-- set-theme work happens in the background and RPCs back when ready.
vim.api.nvim_create_autocmd("BufWritePost", {
  desc = "auto re-apply theme on edit of its config files",
  callback = function(args)
    local theme = args.file:match("orchard%-themes/([^/]+)/[^/]+$")
    if theme then
      vim.fn.jobstart({ "set-theme", theme }, { detach = true })
    end
  end,
})

-- Tmux window-name tracking: rename the surrounding tmux window to
-- the basename of nvim's cwd so the label tracks which project you're
-- in. On exit, hand control back to tmux's automatic-rename so the
-- next command (`zsh`, `git log`, whatever) labels itself.
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
