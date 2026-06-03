#!/usr/bin/env bash
# Join your tailnet — links this machine to the Mac mini's private network.
#
# `tailscale up` prints a URL and opens a browser to authenticate, so it
# lives here rather than in the unattended install.sh. configure-tailscale.sh
# already enabled the tailscaled daemon; this just logs in.
# `--operator=$USER` lets you run `tailscale` commands afterward without
# sudo.
#
# Sign in with the SAME account the Mac mini uses, or the two devices land
# in separate tailnets and can't see each other.
#
# Idempotent: if the backend is already Running (logged in), the script
# prints status and exits.
set -euo pipefail

if ! command -v tailscale >/dev/null 2>&1; then
    echo "tailscale not installed. Run: sudo pacman -S tailscale" >&2
    exit 1
fi

if ! systemctl is-active --quiet tailscaled.service; then
    echo "tailscaled isn't running. Run: bash setup/install/configure-tailscale.sh" >&2
    exit 1
fi

state="$(tailscale status --json 2>/dev/null | jq -r '.BackendState // empty' 2>/dev/null || true)"
if [ "$state" = "Running" ]; then
    printf "Already connected to the tailnet:\n\n"
    tailscale status
    exit 0
fi

cat <<'EOF'

──────────────────────────────────────────────────────────────────────
tailscale — join your tailnet
──────────────────────────────────────────────────────────────────────

`tailscale up` will print a URL and open your browser to authenticate.
Sign in with the SAME account the Mac mini uses (you logged in there
with Google) so both devices share one tailnet.

Press Enter to continue.
EOF
read -r _

sudo tailscale up --operator="$USER"

printf "\nDone. Current tailnet status:\n\n"
tailscale status
