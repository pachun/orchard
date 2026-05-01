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

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GRUB_FILE=/etc/default/grub

# Heal old broken form, if present.
sudo sed -i -E 's|apple_dcp\.show_notch=1|appledrm.show_notch=1|g' "$GRUB_FILE"

if ! grep -qE 'appledrm\.show_notch=1' "$GRUB_FILE"; then
    sudo sed -i -E 's|^(GRUB_CMDLINE_LINUX_DEFAULT="[^"]*)"|\1 appledrm.show_notch=1"|' "$GRUB_FILE"
fi

# Force loglevel=2 (only critical+ on the console). Default Arch ships
# loglevel=3, which lets harmless driver errors like brcmf_dongle_roam
# print over the TTY login prompt. Genuine failures still show; routine
# noise goes only to the journal.
sudo sed -i -E 's|loglevel=[0-9]+|loglevel=2|' "$GRUB_FILE"
if ! grep -qE 'loglevel=[0-9]+' "$GRUB_FILE"; then
    sudo sed -i -E 's|^(GRUB_CMDLINE_LINUX_DEFAULT="[^"]*)"|\1 loglevel=2"|' "$GRUB_FILE"
fi

# Additional boot-noise suppression flags. `splash` hints at plymouth (no-op
# without it), `systemd.show_status=false` hides per-unit START/STARTED
# lines, `rd.udev.log_level=0` silences early udev, and
# `vt.global_cursor_default=0` keeps the blinking cursor off the empty
# black frames between stages.
for flag in splash systemd.show_status=false rd.udev.log_level=0 vt.global_cursor_default=0; do
    if ! grep -qE "(^|\s)${flag}(\s|\")" "$GRUB_FILE"; then
        sudo sed -i -E "s|^(GRUB_CMDLINE_LINUX_DEFAULT=\"[^\"]*)\"|\1 ${flag}\"|" "$GRUB_FILE"
    fi
done

# Skip the GRUB menu — boot the default entry immediately, hold Shift at
# boot if you ever need to override.
sudo sed -i -E 's|^GRUB_TIMEOUT=.*|GRUB_TIMEOUT=0|' "$GRUB_FILE"
if ! grep -qE '^GRUB_TIMEOUT_STYLE=' "$GRUB_FILE"; then
    echo 'GRUB_TIMEOUT_STYLE=hidden' | sudo tee -a "$GRUB_FILE" >/dev/null
else
    sudo sed -i -E 's|^GRUB_TIMEOUT_STYLE=.*|GRUB_TIMEOUT_STYLE=hidden|' "$GRUB_FILE"
fi

sudo grub-mkconfig -o /boot/grub/grub.cfg

# Linux-asahi resets console_loglevel to 4 (warning+) at runtime, so the
# kernel cmdline `loglevel=2` doesn't actually stick. Drop a sysctl.d
# file that systemd-sysctl applies after that reset.
sudo install -m 644 -o root -g root \
    "$HERE/sysctl/00-quiet-console.conf" \
    /etc/sysctl.d/00-quiet-console.conf
