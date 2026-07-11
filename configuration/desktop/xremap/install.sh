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

# On the Dell XPS the thumb key left of the spacebar is Alt, not Super, so
# a drop-in appends a second xremap config that swaps the two (see
# config/dell-xps-alt-super-swap.yml). Apple keyboards already have Super
# under the thumb — the swap is x86-only, and the drop-in is removed there.
. "$TOOLS/machine.sh"
swap_override="$HOME/.config/systemd/user/xremap.service.d/dell-xps-alt-super-swap.conf"
if is_apple_silicon; then
  rm -f "$swap_override"
else
  mkdir -p "$(dirname "$swap_override")"
  cat > "$swap_override" <<'EOF'
[Service]
ExecStart=
ExecStart=%h/.cargo/bin/xremap --watch=config,device %h/.config/xremap/config.yml %h/.config/xremap/dell-xps-alt-super-swap.yml
EOF
fi

systemctl --user daemon-reload
systemctl --user enable xremap.service
systemctl --user restart xremap.service
