#!/usr/bin/env bash
# Allow xremap (and similar user-space input tools) to read /dev/input/event*
# and write to /dev/uinput without sudo. Idempotent — safe to re-run.
#   - puts the user in the `input` group (covers /dev/input/event* reads)
#   - drops a udev rule that gives the input group RW on /dev/uinput
set -euo pipefail

RULES=/etc/udev/rules.d/90-uinput.rules

sudo tee "$RULES" >/dev/null <<'EOF'
KERNEL=="uinput", GROUP="input", MODE="0660", OPTIONS+="static_node=uinput"
EOF

if ! id -nG "$USER" | tr ' ' '\n' | grep -qx input; then
  sudo usermod -aG input "$USER"
fi

sudo udevadm control --reload-rules
sudo udevadm trigger --subsystem-match=misc --attr-match=name=uinput
