#!/usr/bin/env bash
# Trackpad. Installs the libinput quirk that lets disable-while-typing actually
# see your keystrokes — without it the pad is never told you're typing, and a
# resting palm clicks in the middle of a sentence. The quirk file carries the
# reasoning; the short version is that xremap holds an exclusive grab on the
# keyboard libinput was watching, so libinput was watching a muted device.
#
# The quirk isn't DMI-scoped, because the Asahi mac grabs its keyboard the same
# way and has the same hole. On a machine not running xremap it matches nothing.
#
# A change here does not take effect until the compositor restarts, and it is
# worth being precise about why, because the obvious workaround doesn't work:
# libinput loads the whole quirks database once, when its *context* is
# created — not per device. Hyprland's context is created at Hyprland start.
# So rebinding the touchpad's driver re-adds the device but re-matches it
# against the quirks Hyprland already had in memory. Only a compositor restart
# (in practice, a reboot) picks a new file up.
# Idempotent.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

sudo install -Dm644 "$HERE/local-overrides.quirks" \
    /etc/libinput/local-overrides.quirks

# Catches a malformed quirk now rather than at the next boot, when the symptom
# would be a trackpad that silently went back to clicking while you type.
libinput quirks validate >/dev/null 2>&1 \
    || echo "trackpad: libinput rejected the quirks database — check local-overrides.quirks" >&2
