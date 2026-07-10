-- Window split helpers — adds a "zoom" toggle (one window full-screen,
-- restore back to the previous layout). nvim has no native equivalent;
-- we fake it by saving the current layout to a session file with
-- :mksession before maximizing, then sourcing it back on un-zoom.
--
-- Keymaps live in lua/keymaps.lua under the <leader>d* namespace.

local M = {}

local session_file = "/tmp/vim_session_" .. vim.fn.getpid() .. ".vim"

local function is_zoomed()
  return vim.fn.filereadable(session_file) == 1
end

local function can_zoom()
  return vim.fn.winnr("$") > 1
end

-- nvim-tree windows that get re-created by the session-restore step
-- need to be closed manually; sessions don't save their state cleanly.
local function close_nvim_tree_windows()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf_name = vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(win))
    if buf_name:match("NvimTree_%d+") then
      vim.api.nvim_win_close(win, true)
    end
  end
end

-- The session restore can land us on a different buffer; record where
-- we were so we can return to it.
local function save_position()
  return {
    name = vim.api.nvim_buf_get_name(vim.api.nvim_get_current_buf()),
    view = vim.fn.winsaveview(),
  }
end

local function restore_position(saved)
  local current = vim.api.nvim_buf_get_name(vim.api.nvim_get_current_buf())
  if saved.name ~= "" and saved.name ~= current then
    vim.cmd("edit " .. vim.fn.fnameescape(saved.name))
  end
  vim.fn.winrestview(saved.view)
end

local function zoom()
  vim.cmd("mks! " .. session_file)
  vim.cmd("wincmd o")
end

local function unzoom()
  local saved = save_position()
  vim.cmd("silent! source " .. session_file)
  vim.fn.delete(session_file)
  close_nvim_tree_windows()
  restore_position(saved)
end

function M.split()
  if is_zoomed() then
    vim.notify("Unzoom (<leader>d+) before splitting", vim.log.levels.WARN)
  else
    vim.cmd("split")
  end
end

function M.vsplit()
  if is_zoomed() then
    vim.notify("Unzoom (<leader>d+) before splitting", vim.log.levels.WARN)
  else
    vim.cmd("vsplit")
  end
end

function M.toggle_zoom()
  if is_zoomed() then
    unzoom()
  elseif can_zoom() then
    zoom()
  else
    vim.notify("Only one pane open — nothing to zoom", vim.log.levels.WARN)
  end
end

function M.close_split()
  if is_zoomed() then
    unzoom()
  end
  vim.cmd("q")
end

return M
