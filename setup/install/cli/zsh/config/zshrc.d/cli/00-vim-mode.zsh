function use_vim_mode_on_cli {
  bindkey -v

  function use_jj_instead_of_escape {
    switch_to_vim_command_mode=jj
    bindkey -M viins $switch_to_vim_command_mode vi-cmd-mode
  }
  use_jj_instead_of_escape

  # Default viins binds backspace to vi-backward-delete-char, which
  # only deletes characters typed in the CURRENT insert session — try
  # to backspace past where you re-entered insert mode and it does
  # nothing. Rebind to the plain widget that deletes anything to the
  # left. Also fix Ctrl+W (delete word backward) and Ctrl+U (delete
  # to line start) which suffer the same limitation.
  bindkey -M viins '^?' backward-delete-char     # ^? = backspace
  bindkey -M viins '^W' backward-kill-word
  bindkey -M viins '^U' backward-kill-line
}

use_vim_mode_on_cli
