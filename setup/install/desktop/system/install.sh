#!/usr/bin/env bash
# System-level menus + control panel. Wifi menu shells out to nmcli,
# system menu offers power/reboot/lock, system update wraps pacman,
# gnome-control-center is the GTK settings panel (wrapped by a small
# launcher that sets XDG_CURRENT_DESKTOP=GNOME so the panel knows what
# session it's in). All menu UIs use fuzzel (provided by the fuzzel
# feature).
# Idempotent.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

bash "$HERE/../fuzzel/install.sh"

sudo pacman -S --needed --noconfirm gnome-control-center

bash "$TOOLS/link.sh" "$HERE/bin" "$HOME/.local/bin"
bash "$TOOLS/link.sh" "$HERE/dbus-services" "$HOME/.local/share/dbus-1/services"
