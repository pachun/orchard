#!/usr/bin/env bash
# Wayland clipboard. wl-clipboard provides wl-paste/wl-copy; cliphist is
# the daemon that records every copy event and lets you paste older
# ones. Wired to Cmd+Shift+V via a fuzzel picker in hyprland.lua.
# Idempotent.
set -euo pipefail
TOOLS="${TOOLS:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)/tools}"

bash "$TOOLS/install-packages.sh" cliphist wl-clipboard
