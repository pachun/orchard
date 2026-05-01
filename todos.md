no bootloader shown / waiting for selection on restart
auto run start-hyprland so we're not left in a plain tty terminal
tui login
vim/lua setup (I need to do this manually and slowly)
hyprexpo plugin for mission-control-style workspace overview (must be built against pinned hyprland 0.54.3 — vendor the .so the same way as the hypr .pkgs) (map to f3 like mission control)
airpods connection
top bar: time/date, battery, weather, bluetooth, wifi
external monitor connection
nord vpn
imessage integration
icloud files integration
everything looks a little too zoomed in; the whole UI/desktop
screenshot / record tool
color picker tool
drop the orchard aquamarine build once PR #289 merges + new release ships (https://github.com/hyprwm/aquamarine/pull/289). Then: delete setup/install/aquamarine/, delete setup/install/install-aquamarine.sh, remove its line from setup/install.sh, strip the `aquamarine` IgnorePkg entry from /etc/pacman.conf, run `sudo pacman -Syu` to pull the upstream version
home theatre setup w/ mac mini + plex to auto search for, download, populate movies and shows from iptorrents
