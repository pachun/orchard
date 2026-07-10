#!/usr/bin/env bash
# Chromium browser + DRM module + secret-storage backend, with
# force-installed extensions and a theme policy that follows the
# orchard-themes active symlink.
#
# Packages:
#   chromium — the browser
#   widevine — the DRM module Chromium needs to play encrypted
#     streams (Apple TV+, Netflix, etc.). On x86_64 Chromium fetches
#     it itself via the component updater; on aarch64 it can't, so
#     ~/.config/chromium/WidevineCdm stays empty and DRM video
#     silently fails to start. This package (asahi-alarm repo)
#     installs the CDM and registers it with Chromium and Firefox.
#   gnome-keyring — Secret Service backend chromium uses for password
#     storage.
#
# Extension force-install: chromium reads JSON files under
# /etc/chromium/policies/managed/ on every startup and installs
# whatever's listed before the user can even open the browser.
#   - AdGuard AdBlocker — MV3 ad blocker; picked over uBlock Origin
#     Lite (ULL's defaults break sites that rely on third-party
#     scripts).
#   - Privacy.com — virtual cards at checkout.
#   - Vimium C — vim-style browser bindings; owns j/k for smooth
#     per-frame scroll, plus link hints / find-as-you-type.
#
# Theme policy: symlink the active orchard-theme's chromium.json into
# the same managed-policy dir. Active symlink resolves at every read
# so theme switching just needs to swap ~/.config/orchard-themes/active
# and signal chromium to re-read policy.
# Idempotent.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

. "$TOOLS/machine.sh"

packages=(chromium gnome-keyring)
if is_apple_silicon; then
  packages+=(widevine)
fi
sudo pacman -S --needed --noconfirm "${packages[@]}"

bash "$TOOLS/link.sh" "$HERE/config" "$HOME/.config"

POLICY_DIR="/etc/chromium/policies/managed"
UPDATE_URL="https://clients2.google.com/service/update2/crx"

ADGUARD_ADBLOCKER="bgnkhhnnamicmpeenaelnjfhikgbkllg"
PRIVACY_DOT_COM="hmgpakheknboplhmlicfkkgjipfabmhp"
VIMIUM_C="dbepggeogbaibhgnhhndojpepiihcmeb"

sudo mkdir -p "$POLICY_DIR"
sudo tee "$POLICY_DIR/orchard-extensions.json" >/dev/null <<EOF
{
  "ExtensionInstallForcelist": [
    "$ADGUARD_ADBLOCKER;$UPDATE_URL",
    "$PRIVACY_DOT_COM;$UPDATE_URL",
    "$VIMIUM_C;$UPDATE_URL"
  ]
}
EOF

# Theme policy follows the orchard-themes active symlink.
sudo ln -sfn "$HOME/.config/orchard-themes/active/chromium.json" \
    "$POLICY_DIR/orchard-theme.json"
