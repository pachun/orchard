# Pasted content lands in zsh's buffer without triggering a screen redraw —
# characters only appear after the next keypress. Wrap the built-in
# bracketed-paste widget with an explicit `zle redisplay` to force a
# repaint when the paste finishes.
function _paste_then_redisplay {
  zle .bracketed-paste
  zle redisplay
}
zle -N bracketed-paste _paste_then_redisplay
