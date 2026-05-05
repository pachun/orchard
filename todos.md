tui login
hyprexpo plugin for mission-control-style workspace overview (must be built against pinned hyprland 0.54.3 — vendor the .so the same way as the hypr .pkgs) (map to f3 like mission control)
airpods connection / bluetooth
external monitor connection
everything looks a little too zoomed in; the whole UI/desktop
color picker tool

icloud files integration
photos integration
home theatre setup w/ mac mini + plex to auto search for, download, populate movies and shows from iptorrents

drop the orchard aquamarine build once PR #289 merges + new release ships (https://github.com/hyprwm/aquamarine/pull/289). Then: delete setup/install/aquamarine/, delete setup/install/install-aquamarine.sh, remove its line from setup/install.sh, strip the `aquamarine` IgnorePkg entry from /etc/pacman.conf, run `sudo pacman -Syu` to pull the upstream version

nvim plugins explicitly skipped during the boo port (revisit if needed):

- snacks.nvim — folke's UI toolkit; only used in boo for vim.ui.input styling, which noice already covers
- supermaven — AI ghost-text completion; redundant alongside Claude Code
- vim-ruby — ruby filetype enhancements; not currently writing ruby
