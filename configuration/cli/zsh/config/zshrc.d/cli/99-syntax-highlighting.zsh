# typing `ech` will appear red in the cli
# typing `echo` will appear green in the cli
# Must be sourced last so the highlighter wraps all earlier widget
# rebinds (vim-mode, paste fix, etc.).
[ -r /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ] && \
  source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
