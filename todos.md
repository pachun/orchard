tui login

hyprexpo plugin for mission-control-style workspace overview (must be built against pinned hyprland 0.54.3 — vendor the .so the same way as the hypr .pkgs) (map to f3 like mission control)

airpods connection / bluetooth

external monitor connection

everything looks a little too zoomed in; the whole UI/desktop

color picker tool

root's login probably shouldn't be left as "root/root"

swaybar color /styling feels off... maybe colors for foreground fonts need to be adjusted? I'm not sure... arch logo should probably stay white / prominent. We could just hide the bell icon when dnd is off. The icon for nordvpn is misleading when the vpn is off, a shield with a lock is shown. if we do hide dnd when it's off, it should keep showing for like 30 seconds after it's turned off (indicating properly that it's disabled / not on) - that's what mac's does. Then it eventually fades away.

f3 bind to mission control thing

cmd+tab application switcher with the macOS hold-modifier UX. Every off-the-shelf launcher (fuzzel, rofi, walker, anyrun) is a discrete picker — open, navigate, press Enter, close. None implement "hold Cmd, tab through, release commits". Need to build a small Wayland app (Rust + iced or gtk4-rs):
- Grabs Wayland input while open
- Renders a horizontal icon strip overlay
- Tab advances forward, ` (backtick) advances backward
- Watches libinput for Super (Cmd) key release → commits selection via hyprctl focuswindow
- Esc cancels
~400-600 LOC, lives in dotfiles/local/bin/ or as its own setup/install script if it needs cargo build

---

icloud files integration
photos integration
home theatre setup w/ mac mini + plex to auto search for, download, populate movies and shows from iptorrents

drop the orchard aquamarine build once PR #289 merges + new release ships (https://github.com/hyprwm/aquamarine/pull/289). Then: delete setup/install/aquamarine/, delete setup/install/install-aquamarine.sh, remove its line from setup/install.sh, strip the `aquamarine` IgnorePkg entry from /etc/pacman.conf, run `sudo pacman -Syu` to pull the upstream version
