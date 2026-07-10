#!/usr/bin/env bash
# BlueBubbles desktop client — pairs with BlueBubbles Server running
# on an always-on Mac (the Mac handles iMessage; this is the Linux
# UI). Idempotent.
set -euo pipefail

bash "$TOOLS/install-yay.sh"
yay -S --needed --noconfirm bluebubbles-bin
