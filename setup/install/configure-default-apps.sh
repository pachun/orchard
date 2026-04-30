#!/usr/bin/env bash
# Set system-wide default applications via xdg-mime. Writes to
# ~/.config/mimeapps.list. Idempotent — re-runs are no-ops if the values
# are already set.
set -euo pipefail

# Default terminal: ghostty. Used by xdg-terminal-exec and tools that
# launch a terminal via the x-scheme-handler/terminal MIME type.
xdg-mime default com.mitchellh.ghostty.desktop x-scheme-handler/terminal
