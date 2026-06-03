#!/usr/bin/env bash
# Post-install wiring for tailscale. The package ships the tailscaled
# system daemon but leaves it disabled; the CLI (`tailscale up`,
# `tailscale status`) talks to that daemon over a local socket and fails
# with "failed to connect to local tailscaled" until it's running. So:
#
#   1. Enable + start tailscaled.service.
#
# Joining the tailnet (`tailscale up`) is deliberately NOT done here — it
# opens a browser for OAuth, which doesn't belong in the unattended
# install flow. That step lives in setup/connect/tailscale.sh.
#
# Idempotent — `enable --now` is a no-op when the unit is already enabled
# and active.
set -euo pipefail

if ! command -v tailscale >/dev/null 2>&1; then
    echo "tailscale not installed; skipping (install-packages.sh should have handled it)" >&2
    exit 0
fi

sudo systemctl enable --now tailscaled.service
