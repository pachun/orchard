#!/usr/bin/env bash
# Notifications. They appear where the clock is, at the top of the screen: the
# clock fades out, the message fades in, and after its timeout they swap back.
# Click one and it opens the app that sent it. There is no toast, anywhere.
#
# orchard-notifications owns the freedesktop notification bus and draws nothing
# at all — the bar is the display (see waybar-clock). It replaces mako outright
# rather than hiding it, because mako has no way to accept a notification
# without drawing a toast for it: no `invisible` option, and aiming it at an
# output that doesn't exist just makes it fall back to the real one. A daemon
# that draws nothing is less code than a daemon fooled into looking like one.
#
# It needs no package: python-gobject is already here for the wallpaper portal,
# and the bus is all it uses.
# Idempotent.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

bash "$TOOLS/link.sh" "$HERE/bin" "$HOME/.local/bin"
