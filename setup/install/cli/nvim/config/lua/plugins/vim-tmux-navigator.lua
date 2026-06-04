-- Seamless Ctrl-h/j/k/l navigation between nvim splits and tmux panes.
-- Pairs with the `is_vim` ps-detection block in dotfiles/config/tmux/
-- tmux.conf, which forwards Ctrl-hjkl into nvim when nvim is the focused
-- pane and falls back to `select-pane` otherwise.
return { "christoomey/vim-tmux-navigator" }
