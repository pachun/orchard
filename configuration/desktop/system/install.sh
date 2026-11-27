#!/usr/bin/env bash
# System-level menus. Wifi menu shells out to nmcli, system menu offers
# power/reboot/lock, system update wraps pacman. All menu UIs use fuzzel
# (provided by the fuzzel feature).
# Idempotent.
set -euo pipefail
TOOLS="${TOOLS:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)/tools}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# rebuild-detector finds the AUR packages an upgrade left unable to start,
# which system-update then rebuilds.
bash "$TOOLS/install-packages.sh" rebuild-detector

bash "$HERE/../fuzzel/install.sh"
bash "$HERE/../menu/install.sh"

bash "$TOOLS/link.sh" "$HERE/bin" "$HOME/.local/bin"
bash "$TOOLS/link.sh" "$HERE/launcher" "$HOME/.config/launcher"
