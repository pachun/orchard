#!/usr/bin/env bash
# Fingerprint unlock. fprintd owns the reader (the Framework's is Goodix
# 27c6:609c, inside the power button); hyprlock talks to it over D-Bus and
# unlocks on a matched finger — the wiring for that lives in the lock
# feature's hyprlock.conf. Enrollment can't be unattended (it's ten taps of
# your finger), so this prints the command instead of running it.
#
# Gated on the hardware, not the machine: any laptop whose reader announces
# itself as a fingerprint device gets this, machines without one skip it.
# Idempotent.
set -euo pipefail

if ! cat /sys/bus/usb/devices/*/product 2>/dev/null | grep -qi fingerprint; then
    echo "fingerprint: no fingerprint reader on this machine; skipping."
    exit 0
fi

sudo pacman -S --needed --noconfirm fprintd

if ! fprintd-list "$USER" 2>/dev/null | grep -q "^ - "; then
    echo "fingerprint: no fingers enrolled yet — run \`./connect fingerprint\`."
fi
