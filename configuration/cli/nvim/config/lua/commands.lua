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
