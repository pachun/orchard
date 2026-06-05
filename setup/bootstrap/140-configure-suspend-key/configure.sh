#!/usr/bin/env bash
# Tell systemd-logind to ignore the XF86Sleep keysym (what F6 emits on
# Asahi Apple keyboards in fnmode=3). Default logind behavior is to
# suspend on this key; we override so Hyprland's bind on XF86Sleep
# (do-not-disturb toggle, see hyprland.conf) is the only thing that
# fires.
#
# Lives in bootstrap/ rather than install/ because applying it mid-
# session requires `systemctl restart systemd-logind`, which tears down
# every active logind session — including the user's hyprland — and
# kicks them back to the TTY login. Running at bootstrap time means
# logind starts fresh with the new config on the post-bootstrap reboot,
# no restart needed.
#
# Idempotent.
set -euo pipefail

CONF_DIR="/etc/systemd/logind.conf.d"
CONF_FILE="$CONF_DIR/orchard-suspend-key.conf"

sudo mkdir -p "$CONF_DIR"
sudo tee "$CONF_FILE" >/dev/null <<'EOF'
[Login]
HandleSuspendKey=ignore
HandleSuspendKeyLongPress=ignore
EOF
