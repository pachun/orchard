-- Single source of truth for keymaps. The `keymaps` table below is
-- both data (consulted by plugin specs that need a buffer-local
-- override of an existing chord — e.g. nvim-tree's rename) and the
-- input to the registration walk at the bottom of this file.
--
-- Structure: nested namespaces group related keymaps. Leaves carry
-- `mode` + `trigger`. The walk below distinguishes leaves from
-- namespaces by checking for those two fields. Adding a keymap:
--   1. Add a leaf at the right place in `keymaps`.
--   2. Export an action under the same path in keymap_actions.lua.
-- If you do (1) without (2), the iterator notifies (red toast via
-- noice) once per nvim open and skips the missing entry — bad
-- state nags but doesn't block startup.
--
-- The `desc` shown in :map / which-key listings is auto-derived
-- from the path: ["window"]["split_vertically"] becomes "Window
-- Split Vertically". Underscores and namespace boundaries both
-- become spaces; each word gets capitalised.
--
-- External lookup (e.g. nvim-tree referencing the rename chord):
--   require("keymaps").rename.trigger        — top-level leaf
--   require("keymaps")["goto"].definition.trigger  — nested
-- (`goto` needs bracket notation because it's a Lua reserved word.)

local keymap_actions = require("keymap_actions")

local keymaps = {
  exit_insert_mode      = { mode = "i", trigger = "jj"         },
  paste                 = { mode = "c", trigger = "<C-v>"      },
  save                  = { mode = "n", trigger = "<leader>w"  },
  quit                  = { mode = "n", trigger = "<leader>q"  },
  rename                = { mode = "n", trigger = "<leader>rn" },
  clear_highlights      = { mode = "n", trigger = "<leader>nh" },
  toggle_comment        = { mode = "n", trigger = "<C-_><C-_>" },
  reload_nvim_config    = { mode = "n", trigger = "<leader>R"  },
  show_line_diagnostics = { mode = "n", trigger = "<leader>d"  },

  ["goto"] = {
    previous_diagnostic = { mode = "n", trigger = "[d" },
    next_diagnostic     = { mode = "n", trigger = "]d" },
    previous_git_hunk   = { mode = "n", trigger = "[c" },
    next_git_hunk       = { mode = "n", trigger = "]c" },
    definition          = { mode = "n", trigger = "gd" },
    references          = { mode = "n", trigger = "gr" },
  },

  find = {
    files        = { mode = "n", trigger = "<leader>ff" },
    recent_files = { mode = "n", trigger = "<leader>fr" },
    strings      = { mode = "n", trigger = "<leader>fs" },
  },

  window = {
    split_vertically   = { mode = "n", trigger = "<leader>d|" },
    split_horizontally = { mode = "n", trigger = "<leader>d_" },
    equalize           = { mode = "n", trigger = "<leader>de" },
    rotate_forward     = { mode = "n", trigger = "<leader>d{" },
    rotate_backward    = { mode = "n", trigger = "<leader>d}" },
    toggle_zoom        = { mode = "n", trigger = "<leader>d+" },
  },

  toggle_editor = {
    dropdown_suggestions = { mode = "n", trigger = "<leader>dd" },
    ghost_edits          = { mode = "n", trigger = "<leader>sm" },
  },

  toggle = {
    files                 = { mode = "n", trigger = "<leader>ee" },
    files_at_current_file = { mode = "n", trigger = "<leader>ef" },
    git_blame             = { mode = "n", trigger = "<leader>gb" },
  },

  run = {
    test_under_cursor = { mode = "n", trigger = "<leader>s" },
    tests_in_file     = { mode = "n", trigger = "<leader>t" },
    all_tests         = { mode = "n", trigger = "<leader>a" },
  },
}

-- Path → "Title Cased Description". {"window","split_vertically"}
-- becomes "Window Split Vertically".
local function describe(path)
  local words = {}
  for _, segment in ipairs(path) do
    for word in segment:gmatch("[^_]+") do
      table.insert(words, word:sub(1, 1):upper() .. word:sub(2))
    end
  end
  return table.concat(words, " ")
end

-- Walk the same nested path through keymap_actions.
local function lookup_action(path)
  local node = keymap_actions
  for _, segment in ipairs(path) do
    if type(node) ~= "table" then return nil end
    node = node[segment]
  end
  return node
end

-- A leaf is any table with a `trigger` field. Anything else with
-- table-typed values is a namespace and gets recursed into.
local function register(node, path)
  for name, value in pairs(node) do
    if type(value) == "table" then
      local current_path = vim.list_extend({}, path)
      table.insert(current_path, name)
      if value.trigger then
        local action = lookup_action(current_path)
        if action == nil then
          vim.notify(
            ("keymaps: no keymap_action exported for '%s' — keymap skipped"):format(
              table.concat(current_path, ".")
            ),
            vim.log.levels.ERROR
          )
        else
          vim.keymap.set(value.mode, value.trigger, action, { desc = describe(current_path) })
        end
      else
        register(value, current_path)
      end
    end
  end
end

register(keymaps, {})

return keymaps
