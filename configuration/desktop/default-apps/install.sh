#!/usr/bin/env bash
# Default applications via xdg-mime. Writes to ~/.config/mimeapps.list.
# Idempotent — re-runs are no-ops if values are already set.
#
# Currently set:
#   - x-scheme-handler/terminal → ghostty
#     Used by xdg-terminal-exec and tools that launch a terminal
#     via that MIME type.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

bash "$HERE/../ghostty/install.sh"
xdg-mime default com.mitchellh.ghostty.desktop x-scheme-handler/terminal
