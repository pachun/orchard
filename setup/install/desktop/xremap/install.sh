#!/usr/bin/env bash
# xremap — input remapper used for window-class-aware keybinds
# (cmd+c/v/x/a/z outside terminal, etc.). Cargo install with the
# wlroots feature for Wayland support. Needs uinput permissions so
# the daemon can read /dev/input/event* and write to /dev/uinput
# without sudo. Runs as a user systemd service.
# Idempotent.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

bash "$HERE/../../cli/rust/install.sh"
cargo install --locked xremap --features wlroots

# Input permissions: user in `input` group + udev rule that gives
# the input group RW on /dev/uinput.
RULES=/etc/udev/rules.d/90-uinput.rules
sudo tee "$RULES" >/dev/null <<'EOF'
KERNEL=="uinput", GROUP="input", MODE="0660", OPTIONS+="static_node=uinput"
EOF

if ! id -nG "$USER" | tr ' ' '\n' | grep -qx input; then
  sudo usermod -aG input "$USER"
fi

sudo udevadm control --reload-rules
sudo udevadm trigger --subsystem-match=misc --attr-match=name=uinput

# Config + systemd user unit.
bash "$TOOLS/link.sh" "$HERE/config" "$HOME/.config/xremap"
bash "$TOOLS/link.sh" "$HERE/systemd" "$HOME/.config/systemd/user"

systemctl --user daemon-reload
systemctl --user enable --now xremap.service
