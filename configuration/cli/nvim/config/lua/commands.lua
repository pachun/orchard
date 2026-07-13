-- Shift held a beat too long turns :w into :W and :q into :Q, and vim
-- answers "E492: Not an editor command" — a dead end for a keystroke
-- whose intent was never ambiguous. Define the capitalised spellings as
-- real commands so they just do the obvious thing.
--
-- Forwarding bang and args rather than hardcoding the bare command keeps
-- :W! and :W some/path.txt working exactly as their lowercase twins do.
local function also_spelled(capitalised, command)
  vim.api.nvim_create_user_command(capitalised, function(invocation)
    vim.cmd({ cmd = command, bang = invocation.bang, args = invocation.fargs })
  end, { bang = true, nargs = "*", complete = "file" })
end

also_spelled("W", "write")
also_spelled("Wa", "wall")
also_spelled("Q", "quit")
also_spelled("Qa", "qall")
also_spelled("QA", "qall")
also_spelled("Wq", "wq")
also_spelled("WQ", "wq")

-- :md renders this file the way GitHub will, in a window beside this one, and
-- keeps it in step with every save.
--
-- Vim keeps lowercase names for its own commands, so the real one has to be
-- :Md. The abbreviation gives us :md anyway, and fires only when md is the
-- whole line — left unguarded it would rewrite the md in `:e md.txt` too.
local function preview_markdown()
  local file = vim.api.nvim_buf_get_name(0)
  if file == "" then
    vim.notify("Nothing to preview — this buffer has no file yet.", vim.log.levels.WARN)
    return
  end
  vim.cmd("write")
  vim.fn.jobstart({ "markdown-preview", file }, { detach = true })
end

vim.api.nvim_create_user_command("Md", preview_markdown, {})
vim.cmd([[cnoreabbrev <expr> md (getcmdtype() == ":" && getcmdline() ==# "md") ? "Md" : "md"]])
