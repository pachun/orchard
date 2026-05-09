- [ ] tui login

---

icloud files integration
photos integration
home theatre setup w/ mac mini + plex to auto search for, download, populate movies and shows from iptorrents

drop the orchard aquamarine build once PR #289 merges + new release ships (https://github.com/hyprwm/aquamarine/pull/289). Then: delete setup/install/aquamarine/, delete setup/install/install-aquamarine.sh, remove its line from setup/install.sh, strip the `aquamarine` IgnorePkg entry from /etc/pacman.conf, run `sudo pacman -Syu` to pull the upstream version
