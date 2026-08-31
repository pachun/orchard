#!/usr/bin/env bash
# NordVPN client. AUR package + daemon enable + group membership + DNS
# override. Idempotent — re-running is a no-op when everything is
# already set. `nordvpn login` / `connect` stay manual (browser OAuth).
#
# Notes on the steps:
#   1. nordvpn-bin (AUR) provides the daemon + CLI.
#   2. Enable nordvpnd.service. Without it, `nordvpn login` / `connect`
#      fail with "Whoops! Cannot reach System Daemon".
#   3. Add the user to the `nordvpn` group so the CLI socket is
#      accessible without sudo. Group membership only takes effect on
#      the next login session.
#   4. Override the DNS resolvers Nord pushes when connected. Nord's
#      defaults occasionally miss records for individual hosts; 1.1.1.1
#      + 8.8.8.8 trade a small bit of metadata privacy for a much
#      better hit rate.
#   5. Make the package's nordvpn.desktop the handler for nordvpn:// links.
#      The browser login's "Continue" button is one of those; without a
#      registered handler it goes nowhere and the login has to be finished
#      by pasting the link into `nordvpn login --callback`.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

bash "$TOOLS/install-yay.sh"
bash "$TOOLS/aur-install.sh" nordvpn-bin

bash "$TOOLS/link.sh" "$HERE/bin" "$HOME/.local/bin"

sudo systemctl enable --now nordvpnd.service

xdg-mime default nordvpn.desktop x-scheme-handler/nordvpn

if ! id -nG "$USER" | tr ' ' '\n' | grep -qx nordvpn; then
    sudo usermod -aG nordvpn "$USER"
    echo "Added $USER to the nordvpn group — log out and back in for it to take effect."
fi

# `nordvpn set dns` exits non-zero both when the daemon is unreachable
# (group membership not active in this shell yet) AND when the values
# are already set. Distinguish via the message on stdout.
set_dns() {
    nordvpn set dns 1.1.1.1 8.8.8.8 2>&1
}

if ! out=$(set_dns); then
    if printf '%s' "$out" | grep -qi 'already'; then
        :  # already configured, nothing to do
    else
        sleep 2
        if ! out=$(set_dns) || ! printf '%s' "$out" | grep -qi 'already\|set to'; then
            echo "Could not set NordVPN DNS — likely because the nordvpn group" >&2
            echo "isn't active in this shell yet. Re-run this script after a" >&2
            echo "fresh login, or run \`nordvpn set dns 1.1.1.1 8.8.8.8\` manually." >&2
        fi
    fi
fi
