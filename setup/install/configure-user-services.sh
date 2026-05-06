#!/usr/bin/env bash
# Enable the systemd user services that ship in dotfiles/config/systemd/.
# These are linked in by dotfiles/link.sh; this script flips them to
# enabled so they actually start when graphical-session.target activates
# (which Hyprland triggers via its exec-once integration).
set -euo pipefail

systemctl --user daemon-reload
systemctl --user enable xremap.service
# ydotoold (provided by the ydotool pacman pkg) — feeds the rofimoji
# emoji picker on Ctrl+Cmd+Space. Needs to be running before any
# ydotool invocation; running it as a user service keeps it scoped to
# the graphical session.
systemctl --user enable ydotool.service
