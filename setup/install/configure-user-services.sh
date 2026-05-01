#!/usr/bin/env bash
# Enable the systemd user services that ship in dotfiles/config/systemd/.
# These are linked in by dotfiles/link.sh; this script flips them to
# enabled so they actually start when graphical-session.target activates
# (which Hyprland triggers via its exec-once integration).
set -euo pipefail

systemctl --user daemon-reload
systemctl --user enable xremap.service
