#!/usr/bin/env bash
# Trackpad. Installs the libinput quirk that turns press-to-click off on
# the XPS 14's haptic clickpad, leaving tap-to-click as the only way to
# click. The quirk file itself carries the reasoning; the short version is
# that the pad is a force sensor with no switch, so a resting palm presses
# it hard enough to fire BTN_LEFT, and libinput's disable-while-typing
# deliberately won't gate a physical button.
#
# The quirk is DMI-scoped to the XPS, so installing it on the Asahi mac is
# a no-op — its trackpad is handled by the palm-filter daemon instead.
# That means this runs unconditionally and needs no machine check.
#
# A change here does not take effect until the compositor restarts, and it is
# worth being precise about why, because the obvious workaround doesn't work:
# libinput loads the whole quirks database once, when its *context* is
# created — not per device. Hyprland's context is created at Hyprland start.
# So rebinding the touchpad's driver re-adds the device but re-matches it
# against the quirks Hyprland already had in memory, and the click survives.
# Only a compositor restart (in practice, a reboot) picks a new file up.
#
# On a fresh machine that's free: ./configure ends in a reboot, so the quirk
# is loaded on the first real boot. Re-running ./configure inside a live
# session skips the reboot, and the trackpad keeps its physical click until
# the next one.
# Idempotent.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

sudo install -Dm644 "$HERE/local-overrides.quirks" \
    /etc/libinput/local-overrides.quirks

# Catches a malformed quirk now rather than at the next boot, when the
# symptom would be a trackpad that silently kept its physical click.
libinput quirks validate >/dev/null 2>&1 \
    || echo "trackpad: libinput rejected the quirks database — check local-overrides.quirks" >&2
