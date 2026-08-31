#!/usr/bin/env bash
# Mount the always-on Mac mini's iCloud Drive folder
# (~/Library/Mobile Documents/com~apple~CloudDocs) onto this machine
# over SSH so iCloud-stored docs are editable locally. Rides over the
# tailscale link so the mount works on or off the home network.
# `icloud` script handles mount/unmount; this just ensures both
# transport deps are present and the script is on PATH.
# Idempotent.
set -euo pipefail
TOOLS="${TOOLS:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)/tools}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

bash "$HERE/../sshfs/install.sh"
bash "$HERE/../tailscale/install.sh"

bash "$TOOLS/link.sh" "$HERE/bin" "$HOME/.local/bin"
