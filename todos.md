- [ ] tui login
- [ ] f3 bind to mission control thing
- [ ] external monitor connection
- [ ] chrome feels too zoomed in - keep configed to 90% zoom somehow?
- [ ] color picker tool
- [ ] root's login probably shouldn't be left as "root/root"

---

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
