#!/usr/bin/env bash
# One clipboard across every machine you own. Copy on one laptop, paste on
# the next — the way Apple's Universal Clipboard behaves between Macs.
#
# Rides two features that are already here: the clipboard feature's
# wl-paste --watch, which fires on every copy, and the tailscale feature,
# which gives every machine a private address and knows who owns each
# peer. That ownership is the whole trust model: a machine only pastes
# what came from another machine on the same Tailscale account, so there
# are no keys to copy around and nothing named after anyone.
#
# hyprland.lua starts the receiver and the watcher at login; installing from
# inside a session starts them right away.
#
# Idempotent.
set -euo pipefail
TOOLS="${TOOLS:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)/tools}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

bash "$HERE/../clipboard/install.sh"
bash "$HERE/../tailscale/install.sh"

bash "$TOOLS/link.sh" "$HERE/bin" "$HOME/.local/bin"

inside_a_desktop_session() { [ -n "${WAYLAND_DISPLAY:-}" ]; }
inside_a_desktop_session && "$HERE/bin/restart-shared-clipboard"
