#!/usr/bin/env bash
# Spotify's native Linux desktop client. spotify-launcher (official extra
# repo) fetches the real client from Spotify's apt repository and keeps it
# current. Replaces the chromium --app web player, which was only ever a
# workaround for the belief that no Linux client existed — and which stored
# its login as a session cookie that didn't survive a chrome restart, so it
# demanded a fresh 2FA sign-in every time. The native app persists its login
# normally. Bound to Cmd+M via hyprland's $musicApplication.
#
# First `spotify-launcher` run downloads the client (a few hundred MB), so
# run it once by hand after install to prime it and sign in.
#
# The linked spotify-launcher.conf is what keeps the window on Wayland rather
# than XWayland — see its comments.
# Idempotent.
set -euo pipefail
TOOLS="${TOOLS:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)/tools}"

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

sudo pacman -S --needed --noconfirm spotify-launcher

bash "$TOOLS/link.sh" "$HERE/config" "$HOME/.config"
