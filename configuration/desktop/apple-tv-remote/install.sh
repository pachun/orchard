#!/usr/bin/env bash
# Control the Apple TVs from the keyboard. pyatv speaks Apple's Companion
# protocol (what the Siri Remote and iPhone remote use); its atvremote CLI
# does discovery, pairing, and every remote button. Installed as a uv tool —
# per-user, no AUR build, atvremote lands in ~/.local/bin. Pairing needs a
# PIN read off each TV, so it lives in ./connect apple-tv; the remote itself
# is bin/apple-tv-remote.
# Idempotent.
set -euo pipefail
TOOLS="${TOOLS:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)/tools}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

sudo pacman -S --needed --noconfirm uv

uv tool install --quiet pyatv

bash "$TOOLS/link.sh" "$HERE/bin" "$HOME/.local/bin"
