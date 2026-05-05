#!/usr/bin/env bash
# Force-install chromium extensions via the ExtensionInstallForcelist
# policy. Chromium reads JSON files under /etc/chromium/policies/managed/
# on every startup and installs whatever's listed before the user can
# even open the browser. Idempotent — re-running rewrites the same
# file.
#
# Currently installed:
#   - AdGuard AdBlocker (bgnkhhnnamicmpeenaelnjfhikgbkllg)
#       Manifest V3 ad blocker. Picked over uBlock Origin Lite (ULL)
#       because ULL's default filter level breaks sites that rely on
#       third-party scripts, while AdGuard's defaults block ads without
#       nuking analytics/CDN payloads. AdGuard is the same company
#       behind the popular paid Safari blocker.
#   - Privacy.com (hmgpakheknboplhmlicfkkgjipfabmhp)
#       Generates one-time / merchant-locked virtual cards at checkout
#       so the real card number never leaves the Privacy.com vault.
#
# To add another extension: get its ID from the Chrome Web Store URL
# (the long string at the end), then append a "<id>;<update_url>"
# entry to the array below.
set -euo pipefail

if ! command -v chromium >/dev/null 2>&1; then
    echo "chromium not installed; skipping extension policy" >&2
    exit 0
fi

POLICY_DIR="/etc/chromium/policies/managed"
POLICY_FILE="$POLICY_DIR/orchard-extensions.json"
UPDATE_URL="https://clients2.google.com/service/update2/crx"

# Chrome Web Store extension IDs. Each is the long string at the end of
# the extension's chromewebstore.google.com URL. Add new entries here
# and reference them in the JSON below.
ADGUARD_ADBLOCKER="bgnkhhnnamicmpeenaelnjfhikgbkllg"
PRIVACY_DOT_COM="hmgpakheknboplhmlicfkkgjipfabmhp"

sudo mkdir -p "$POLICY_DIR"
sudo tee "$POLICY_FILE" >/dev/null <<EOF
{
  "ExtensionInstallForcelist": [
    "$ADGUARD_ADBLOCKER;$UPDATE_URL",
    "$PRIVACY_DOT_COM;$UPDATE_URL"
  ]
}
EOF
