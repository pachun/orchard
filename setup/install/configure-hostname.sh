#!/usr/bin/env bash
# Set the system hostname if it's still the Arch Linux ARM default
# ("alarm"). Prompts the user instead of hardcoding so the install is
# portable across people. Idempotent — skips entirely if the hostname
# is already something other than alarm.
set -euo pipefail

current=$(hostnamectl --static 2>/dev/null || echo alarm)

if [[ "$current" != "alarm" ]]; then
    exit 0
fi

cat <<'EOF'

Hostname is currently the Arch Linux ARM default ("alarm"). Pick a new
one — letters, digits, and hyphens; will appear on the TTY login prompt
and as your shell hostname.

EOF

read -rp "Hostname: " name

if [[ -z "$name" ]]; then
    echo "No hostname entered; leaving as alarm. Re-run this script later to set it."
    exit 0
fi

sudo hostnamectl set-hostname "$name"
echo "Hostname set to $name."
