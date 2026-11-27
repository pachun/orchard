#!/usr/bin/env bash
# Tailscale mesh VPN. Installs the package and enables the system
# daemon. Joining the tailnet (`tailscale up`) needs an interactive
# browser OAuth and lives in connections/tailscale — not here.
# Idempotent.
set -euo pipefail
TOOLS="${TOOLS:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)/tools}"

bash "$TOOLS/install-packages.sh" tailscale
sudo systemctl enable --now tailscaled.service
