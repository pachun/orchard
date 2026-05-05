tui login
vim/lua setup (I need to do this manually and slowly)
hyprexpo plugin for mission-control-style workspace overview (must be built against pinned hyprland 0.54.3 — vendor the .so the same way as the hypr .pkgs) (map to f3 like mission control)
airpods connection / bluetooth
external monitor connection
everything looks a little too zoomed in; the whole UI/desktop
color picker tool

icloud files integration
photos integration
home theatre setup w/ mac mini + plex to auto search for, download, populate movies and shows from iptorrents

drop the orchard aquamarine build once PR #289 merges + new release ships (https://github.com/hyprwm/aquamarine/pull/289). Then: delete setup/install/aquamarine/, delete setup/install/install-aquamarine.sh, remove its line from setup/install.sh, strip the `aquamarine` IgnorePkg entry from /etc/pacman.conf, run `sudo pacman -Syu` to pull the upstream version

nvim plugins/keymaps still missing vs old boo setup, ranked:
- nvim-cmp — popup completion menu wired to LSP (C-j/k navigate, C-l confirm)
- comment.nvim — toggle-comment via C-_ C-_; treesitter-aware (JSX vs JS comments)
- vim-test — leader s/t/a runs nearest test / file / suite
- lsp-file-operations — renaming a file in nvim-tree updates imports project-wide via LSP
- split-management keymaps (leader d|, d_, d+, de) for vsplit / split / zoom / equalize
- blame.nvim — :BlameToggle inline git blame side column (gitsigns has a lighter alt)
- snacks.nvim — folke's UI toolkit; mainly vim.ui.input styling (noice already covers most)
- supermaven — AI completion
- vim-ruby — ruby filetype enhancements
- autocmd to rename the tmux window to the cwd basename when nvim opens / DirChanged
