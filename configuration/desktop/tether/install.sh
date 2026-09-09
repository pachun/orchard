#!/usr/bin/env bash
# Tether — bridges an iPhone to this desktop directly, no Mac in the middle:
# clipboard and file transfer over WiFi (Bonjour + mTLS), SMS/iMessage and
# notification mirroring over Bluetooth (MAP/PBAP/ANCS). Runs alongside
# BlueBubbles while we evaluate it. https://github.com/zackb/tether
#
# The package deliberately leaves two pieces of Bluetooth setup to the admin
# because they change how the machine presents itself to every device, not
# just the iPhone. We want both, so this applies them:
#   bluetooth.service drop-in — runs bluetoothd with --experimental, which
#     exposes the per-transport Bearer.LE1 interface that ANCS notification
#     mirroring rides on. Must be in place before pairing; a bond made without
#     it has no LE half and has to be redone. Carried in this folder since
#     tether-bin 0.2.26 stopped shipping the file.
#   tether-btclass@hci0.service — sets the adapter's Class of Device to
#     A/V Hands-Free after every bluetoothd start, since bluetoothd resets it
#     and the iPhone refuses MAP/PBAP to the default class.
# `tether --bt-setup` reports anything still missing.
#
# tetherd is a per-user daemon (socket under $XDG_RUNTIME_DIR). It runs as
# the tetherd.service user unit so it restarts on failure and so
# restart-upgraded-daemons can restart it after a package upgrade.
# hyprland.conf starts the unit once the Wayland session env has been
# imported into the user manager (the clipboard bridge needs it); here it
# is only started if a session is already up so a fresh install can be
# paired without logging out.
# Idempotent.
set -euo pipefail
TOOLS="${TOOLS:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)/tools}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

bluetoothd_drop_in=/etc/systemd/system/bluetooth.service.d/tether-experimental.conf
repo_drop_in="$HERE/tether-experimental.conf"
adapter=hci0

install_packages() {
  bash "$TOOLS/install-yay.sh"
  bash "$TOOLS/aur-install.sh" tether-bin
}

enable_mdns_discovery() {
  sudo systemctl enable --now avahi-daemon.service
}

bluetoothd_drop_in_is_current() {
  cmp -s "$repo_drop_in" "$bluetoothd_drop_in"
}

apply_bluetoothd_drop_in() {
  sudo install -Dm644 "$repo_drop_in" "$bluetoothd_drop_in"
  sudo systemctl daemon-reload
  sudo systemctl restart bluetooth.service
}

enable_adapter_class_fix() {
  sudo systemctl enable --now "tether-btclass@${adapter}.service"
}

install_user_unit() {
  bash "$TOOLS/link.sh" "$HERE/systemd" "$HOME/.config/systemd/user"
  systemctl --user daemon-reload
}

start_daemon_in_current_session() {
  [ -n "${WAYLAND_DISPLAY:-}" ] || return 0
  systemctl --user start tetherd.service
}

install_packages
enable_mdns_discovery
bluetoothd_drop_in_is_current || apply_bluetoothd_drop_in
enable_adapter_class_fix
install_user_unit
start_daemon_in_current_session
