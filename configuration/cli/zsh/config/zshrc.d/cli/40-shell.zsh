# zsh asserts itself as the user's shell. chsh updates /etc/passwd, but
# $SHELL only re-reads from there on next login — so any tools that
# spawn child processes via $SHELL (tmux, vim's :sh, less's !, etc.)
# would otherwise see the stale value from the session that ran chsh.
export SHELL=/usr/bin/zsh
