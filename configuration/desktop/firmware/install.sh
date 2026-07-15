#!/usr/bin/env bash
# Installs fwupd, the updater for the firmware baked into the machine's
# own hardware — BIOS/UEFI, the SSD controller, Thunderbolt, the dock.
# Think of it as pacman for firmware: it pulls from LVFS (the vendor
# firmware service) the way pacman pulls from mirrors, interrogating each
# device, comparing against LVFS, and flashing what's behind.
#
# The refresh timer keeps the available-update list current. Applying is
# left deliberate (`fwupdmgr update`, surfaced in the update UI) rather
# than automatic: system firmware stages and flashes on the next reboot,
# and that shouldn't happen behind your back.
# Idempotent.
set -euo pipefail

sudo pacman -S --needed --noconfirm fwupd
sudo systemctl enable --now fwupd-refresh.timer
