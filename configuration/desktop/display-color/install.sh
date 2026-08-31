#!/usr/bin/env bash
# Display colour correction — Dell XPS OLED only. The panel ships an
# uncalibrated, green-tinted white balance on Linux (Windows loads a Dell
# factory profile we don't have here), which turns dark blues green. This
# hand-matches it to a MacBook Air. gammawb is a tiny wlr-gamma-control
# client that loads a per-channel gamma ramp and holds it for the session;
# apply-display-color runs it at login (no-op on Apple panels), and `wb`
# is the live tuning + snapshot tool used to find the values. Idempotent.
set -euo pipefail
TOOLS="${TOOLS:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)/tools}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$TOOLS/machine.sh"

# wb + the login applier go on every machine; the applier no-ops on Apple
# panels, so the shared Hyprland exec-once (below) is harmless there.
bash "$TOOLS/link.sh" "$HERE/bin" "$HOME/.local/bin"

# The gamma client is only needed on the Dell OLED. Build it from source so
# there's no committed binary and it matches the running libs. Runs before
# the hyprland feature, so pull the build deps in explicitly.
if is_dell; then
  sudo pacman -S --needed --noconfirm gcc wayland

  build="$(mktemp -d)"
  wayland-scanner client-header "$HERE/src/wlr-gamma-control-unstable-v1.xml" "$build/wlr-gamma-control-client-protocol.h"
  wayland-scanner private-code  "$HERE/src/wlr-gamma-control-unstable-v1.xml" "$build/wlr-gamma-control-protocol.c"
  gcc -O2 -I"$build" "$HERE/src/gammawb.c" "$build/wlr-gamma-control-protocol.c" \
    -o "$HOME/.local/bin/gammawb" -lwayland-client -lm
  rm -rf "$build"

  # Re-apply live so a re-run picks up value changes without a re-login.
  # (First bringup reboots into Hyprland, where the exec-once applies it.)
  if pgrep -x Hyprland >/dev/null 2>&1; then
    pkill -x gammawb 2>/dev/null || true
    sleep 0.3
    setsid nohup "$HOME/.local/bin/apply-display-color" >/dev/null 2>&1 &
  fi
fi
