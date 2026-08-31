#!/usr/bin/env bash
# Claude's native desktop app — a general-purpose chat client, not just for
# coding. Anthropic ships an official Linux build (beta, June 2026) through
# their apt repo for Debian/Ubuntu only; the `claude-desktop` AUR package
# repackages that same official .deb verbatim (from downloads.claude.ai, with
# upstream-published checksums), which is how it reaches Arch.
#
# It's an Electron app. env = ELECTRON_OZONE_PLATFORM_HINT,auto in hyprland.conf
# is what puts its window on Wayland rather than XWayland — without it the app
# renders through XWayland and looks soft on the HiDPI laptop panel. Launch and
# window class are wired to Cmd+Shift+O there too.
#
# First launch signs you in through the browser. Cowork (the agentic mode) will
# additionally download a ~1.3 GB VM image that expands to ~12 GB under
# ~/.config/Claude/ and wants /dev/kvm access — none of which the plain chat
# app touches, so ignore it unless you use Cowork.
# Idempotent.
set -euo pipefail

# configure exports TOOLS; fall back to the repo's tools dir when this feature
# is run on its own, so `bash .../claude-desktop/install.sh` works without it.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOLS="${TOOLS:-$(cd "$HERE/../../../tools" && pwd)}"

bash "$TOOLS/install-yay.sh"

bash "$TOOLS/aur-install.sh" claude-desktop

# Keep the session signed in through a claude:// link or any launcher, the same
# way the Cmd+Shift+O keybind already does. Chromium picks its credential
# backend from the desktop environment and doesn't recognize Hyprland, so it
# falls back to the "basic" store, safeStorage reports encryption unavailable,
# and the app won't persist the login. --password-store=gnome-libsecret names
# the backend outright (gnome-keyring is running and unlocked).
#
# The flag has to ride on every launch, so a user-level .desktop override
# shadows the packaged one and adds it. It's regenerated from whatever the
# package currently ships rather than hand-written, so it can't drift out of
# sync with upstream when the app updates.
add_libsecret_flag_to_exec_lines() {
  sed -E 's#^(Exec=\S*claude-desktop)#\1 --password-store=gnome-libsecret#'
}

packaged_launcher=/usr/share/applications/com.anthropic.Claude.desktop
user_launcher="$HOME/.local/share/applications/com.anthropic.Claude.desktop"

if [ -f "$packaged_launcher" ]; then
  mkdir -p "$(dirname "$user_launcher")"
  add_libsecret_flag_to_exec_lines < "$packaged_launcher" > "$user_launcher"
  command -v update-desktop-database >/dev/null 2>&1 &&
    update-desktop-database "$(dirname "$user_launcher")" 2>/dev/null || true
fi
