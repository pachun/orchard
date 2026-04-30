#!/usr/bin/env bash
# Append `appledrm.show_notch=1` to GRUB's default kernel command line so
# the Asahi appledrm driver exposes the full display height including
# the strip beside the camera notch. Without it the kernel crops the
# notch row entirely and Hyprland never sees those pixels — the result
# is a black band at the top of the screen and waybar can't be placed
# there. The Asahi wiki/docs still call this `apple_dcp.show_notch`,
# but the module's real name in 6.19+ is `appledrm`; verified with
# `modinfo appledrm | grep show_notch`.
#
# Idempotent — re-runs are no-ops if the parameter is already present,
# and old `apple_dcp.show_notch=1` entries get rewritten to the correct
# module name so machines that ran the earlier broken version self-heal.
set -euo pipefail

GRUB_FILE=/etc/default/grub

# Heal old broken form, if present.
sudo sed -i -E 's|apple_dcp\.show_notch=1|appledrm.show_notch=1|g' "$GRUB_FILE"

if ! grep -qE 'appledrm\.show_notch=1' "$GRUB_FILE"; then
    sudo sed -i -E 's|^(GRUB_CMDLINE_LINUX_DEFAULT="[^"]*)"|\1 appledrm.show_notch=1"|' "$GRUB_FILE"
fi

sudo grub-mkconfig -o /boot/grub/grub.cfg
