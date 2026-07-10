-- :TestNearest / :TestFile / :TestSuite. Keymaps in lua/keymaps.lua.
--
-- Custom strategy: when invoked, find a sibling tmux pane that's idle
-- (running zsh, not a command) and in the same cwd, then `send-keys`
-- the test command there. Result: the test runs in a visible side pane
-- without taking over the nvim window. Falls back to a notice if no
-- matching pane exists.
return {
  "vim-test/vim-test",
  config = function()
    local function tmux_panes()
      return vim.fn.systemlist(
        "tmux list-panes -F '#{pane_index} #{pane_pid} #{pane_current_command} #{pane_current_path}'"
      )
    end

    local function first_idle_pane_in_cwd()
      local cwd = vim.fn.getcwd()
      for _, line in ipairs(tmux_panes()) do
        local index, _, command, path = line:match("^(%d+) (%d+) ([%w%p]*) (.+)$")
        if command == "zsh" and path == cwd then
          return index
        end
      end
      return nil
    end

    local function send_to_pane(cmd_str)
      local pane = first_idle_pane_in_cwd()
      if not pane then
        print("vim-test: no idle tmux pane in " .. vim.fn.getcwd())
        return
      end
      vim.fn.system("tmux send-keys -t " .. pane .. " " .. vim.fn.shellescape(cmd_str) .. " C-m")
    end

    -- vim-test's jest runner escapes the regex metacharacters ( ) [ ] twice
    -- (test#base#escape_regex, then again in build_position), so a test name
    -- like `foo()` reaches jest's -t as `foo\\(\\)` and matches nothing.
    -- Collapse the redundant backslash so -t stays a valid regex.
    local function unescape_double_escaped_metachars(cmd_str)
      return (cmd_str:gsub("\\\\([%(%)%[%]])", "\\%1"))
    end

    vim.g["test#custom_strategies"] = {
      send_to_tmux_pane = function(cmd)
        local cmd_str = type(cmd) == "table" and table.concat(cmd, " ") or cmd
        send_to_pane(unescape_double_escaped_metachars(cmd_str))
      end,
    }
    vim.g["test#strategy"] = "send_to_tmux_pane"
  end,
}
