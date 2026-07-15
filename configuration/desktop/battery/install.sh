#!/usr/bin/env bash
# Intel laptop power + thermal management. Two daemons:
#   - thermald: watches CPU temperature and steers Intel's power limits
#     so the chip backs off smoothly under sustained load instead of
#     relying on the firmware's blunt trip points — more sustained
#     performance, a cooler chassis. Fully automatic, no modes.
#   - power-profiles-daemon: the battery / balanced / performance switch
#     (the Mac-style "low power mode"). Defaults to balanced and needs no
#     interaction; it just makes the modes available if ever wanted.
# Intel/x86 only — thermald is Intel-specific, and the Apple-silicon Mac
# manages its own power and thermals.
set -euo pipefail

. "$TOOLS/machine.sh"

is_apple_silicon && exit 0

sudo pacman -S --needed --noconfirm thermald power-profiles-daemon
sudo systemctl enable --now thermald.service power-profiles-daemon.service
