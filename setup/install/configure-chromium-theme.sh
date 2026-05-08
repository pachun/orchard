#!/usr/bin/env bash
# Symlink the active orchard-theme's chromium.json into chromium's
# managed-policy dir so chromium picks up the matching toolbar tint
# (BrowserThemeColor) and color scheme (BrowserColorScheme).
#
# The symlink resolves through ~/.config/orchard-themes/active to
# the current theme's chromium.json on every read — so set-theme
# just needs to swap the active symlink and signal chromium to
# re-read policy. No sudo needed at theme-switch time.
#
# Idempotent — re-running the installer leaves the symlink in
# place if it already points at the right target.
set -euo pipefail

if ! command -v chromium >/dev/null 2>&1; then
    echo "chromium not installed; skipping theme policy" >&2
    exit 0
fi

POLICY_DIR="/etc/chromium/policies/managed"
POLICY_FILE="$POLICY_DIR/orchard-theme.json"
TARGET="$HOME/.config/orchard-themes/active/chromium.json"

sudo mkdir -p "$POLICY_DIR"
sudo ln -sfn "$TARGET" "$POLICY_FILE"
