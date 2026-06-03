#!/usr/bin/env bash
# Mount the Mac mini's iCloud Drive at ~/icloud over sshfs (via tailscale).
#
# Interactive because the first run's ssh-copy-id needs the Mac's login
# password once — same reason gcalcli lives here and not in install.sh.
#
# One-time prereqs ON THE MAC (can't be done from this machine):
#   - System Settings → General → Sharing → Remote Login: ON
#   - Tailscale installed and signed into the SAME account as this
#     machine (see setup/connect/tailscale.sh)
#
# What this does, all idempotent:
#   1. Make sure we have an ed25519 key, and trust the Mac's host key.
#   2. ssh-copy-id our key to the Mac (skips if already installed).
#   3. Write + enable a systemd --user service that keeps the iCloud
#      Drive folder mounted at ~/icloud, reconnecting if the link drops.
#
# Re-running is safe: it stops any current mount and re-establishes it.
set -euo pipefail

MAC_HOST="mac-mini"   # the Mac's tailnet (MagicDNS) name
MAC_USER="nick"       # the Mac's macOS login (short) name
MOUNT_POINT="$HOME/icloud"
REMOTE_PATH="Library/Mobile Documents/com~apple~CloudDocs"  # relative to the Mac's home
KEY="$HOME/.ssh/id_ed25519"

# Defaults above are this setup's known Mac; prompt so the script is
# portable to a differently-named Mac or user.
read -rp "Mac tailnet hostname [$MAC_HOST]: " ans || true; MAC_HOST="${ans:-$MAC_HOST}"
read -rp "Mac username [$MAC_USER]: " ans || true; MAC_USER="${ans:-$MAC_USER}"

# 1. Key + host trust.
if [ ! -f "$KEY" ]; then
    ssh-keygen -t ed25519 -N "" -f "$KEY"
fi
if ! ssh-keygen -F "$MAC_HOST" >/dev/null 2>&1; then
    ssh-keyscan -H "$MAC_HOST" >> "$HOME/.ssh/known_hosts" 2>/dev/null
fi

# 2. Authorize this machine on the Mac (prompts for the Mac password only
# the first time; afterward it reports the key is already installed).
ssh-copy-id -i "$KEY.pub" "$MAC_USER@$MAC_HOST"

# 3. Persistent mount as a systemd --user service. sshfs runs in the
# foreground (-f) so systemd supervises it; reconnect + keepalives ride
# out tailscale blips and Mac sleep, and Restart handles a hard drop.
SERVICE_DIR="$HOME/.config/systemd/user"
SERVICE="$SERVICE_DIR/icloud-mount.service"
mkdir -p "$SERVICE_DIR" "$MOUNT_POINT"
cat > "$SERVICE" <<EOF
[Unit]
Description=Mount iCloud Drive from $MAC_USER@$MAC_HOST over sshfs
After=default.target

[Service]
Type=simple
ExecStartPre=/usr/bin/mkdir -p $MOUNT_POINT
ExecStart=/usr/bin/sshfs -f -o reconnect,ServerAliveInterval=15,ServerAliveCountMax=3,idmap=user,IdentityFile=$KEY "$MAC_USER@$MAC_HOST:$REMOTE_PATH" $MOUNT_POINT
ExecStop=/usr/bin/fusermount3 -u $MOUNT_POINT
Restart=on-failure
RestartSec=10

[Install]
WantedBy=default.target
EOF

systemctl --user daemon-reload
systemctl --user stop icloud-mount.service 2>/dev/null || true
if mountpoint -q "$MOUNT_POINT"; then
    fusermount3 -u "$MOUNT_POINT" 2>/dev/null || true
fi
systemctl --user enable --now icloud-mount.service

sleep 1
if mountpoint -q "$MOUNT_POINT"; then
    echo "iCloud Drive mounted at $MOUNT_POINT ✓"
else
    echo "Mount didn't come up — check: systemctl --user status icloud-mount.service" >&2
    exit 1
fi
