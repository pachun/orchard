#!/usr/bin/env bash
# Post-install wiring for the nordvpn-bin AUR package. Three steps that
# the package itself doesn't handle:
#
#   1. Enable + start the nordvpnd daemon (the CLI talks to it via
#      socket; without this, `nordvpn login` / `connect` fail with
#      "Whoops! Cannot reach System Daemon").
#   2. Add the user to the `nordvpn` group so the CLI socket is
#      accessible without sudo. Group membership only takes effect on
#      the next login session — the script prints a reminder if the
#      user wasn't already in the group.
#   3. Override the DNS resolvers Nord pushes when connected. Nord's
#      default resolvers occasionally miss records for individual
#      hosts (split-horizon / propagation lag), causing
#      ERR_NAME_NOT_RESOLVED on otherwise-working sites. 1.1.1.1 +
#      8.8.8.8 trade a small bit of metadata privacy (DNS now goes to
#      Cloudflare/Google instead of Nord) for far better hit rate.
#
# Idempotent — re-running is a no-op when everything is already set.
# `nordvpn login` and `nordvpn connect` stay manual; both need an
# interactive browser OAuth flow.
set -euo pipefail

if ! command -v nordvpn >/dev/null 2>&1; then
    echo "nordvpn not installed; skipping (install-aur.sh should have handled it)" >&2
    exit 0
fi

sudo systemctl enable --now nordvpnd.service

if ! id -nG "$USER" | tr ' ' '\n' | grep -qx nordvpn; then
    sudo usermod -aG nordvpn "$USER"
    echo "Added $USER to the nordvpn group — log out and back in for it to take effect."
fi

# `nordvpn set dns` exits non-zero both when the daemon is unreachable
# (group membership not active in this shell yet) AND when the values
# are already set. Distinguish via the message on stdout — "already
# set" is a no-op, anything else is a real failure worth reporting.
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
