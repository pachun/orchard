#!/usr/bin/env bash
# Two ways for updates to arrive, switched from the system menu's Updates
# row. Edge is Arch as it ships: the mirror list follows the live mirrors
# (the faster-arch-mirrors feature) and something new is pending most hours
# of most days. Batched holds the mirror list at one dated snapshot from the
# Arch Linux Archive and moves it forward once a week, so a week of updates
# arrives together and nothing is pending in between.
#
# The channel is whichever of the two wrote /etc/pacman.d/mirrorlist last;
# there is no setting stored anywhere else to disagree with it. system-update
# is the same on both.
#
# The switch and the weekly advance run as root, so they are copied to
# /usr/local/bin and owned by root — a link back into this repo would let
# anything running as this user rewrite a script polkit runs as root.
#
# x86 Arch only; the Arch Linux Archive does not carry Arch Linux ARM, so the
# Apple-silicon Mac stays on live mirrors.
# Idempotent.
set -euo pipefail
TOOLS="${TOOLS:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)/tools}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

. "$TOOLS/machine.sh"

is_apple_silicon && exit 0

bash "$HERE/../faster-arch-mirrors/install.sh"
bash "$HERE/../menu/install.sh"
bash "$HERE/../polkit/install.sh"

sudo pacman -S --needed --noconfirm curl

sudo install -m 755 "$HERE/root/set-update-channel" /usr/local/bin/set-update-channel
sudo install -m 755 "$HERE/root/advance-update-batch" /usr/local/bin/advance-update-batch
sudo install -m 644 "$HERE/root/advance-update-batch.service" /etc/systemd/system/advance-update-batch.service
sudo install -m 644 "$HERE/root/advance-update-batch.timer" /etc/systemd/system/advance-update-batch.timer
sudo install -m 644 "$HERE/root/orchard.set-update-channel.policy" /usr/share/polkit-1/actions/orchard.set-update-channel.policy
sudo systemctl daemon-reload

bash "$TOOLS/link.sh" "$HERE/bin" "$HOME/.local/bin"
bash "$TOOLS/link.sh" "$HERE/launcher" "$HOME/.config/launcher"
