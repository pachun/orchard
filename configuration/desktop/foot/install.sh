#!/usr/bin/env bash
# Tiny Wayland terminal we don't actually use — present only because
# hyprland-welcome's "is there a terminal?" check hardcodes a list of
# specific terminal binaries (kitty/alacritty/foot/...) and ghostty
# isn't on it. foot is the lightest of the supported ones.
# Idempotent.
set -euo pipefail
TOOLS="${TOOLS:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)/tools}"

bash "$TOOLS/install-packages.sh" foot
