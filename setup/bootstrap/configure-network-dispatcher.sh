#!/usr/bin/env bash
# Install NetworkManager dispatcher scripts (vendored under
# ./network-dispatcher/) into /etc/NetworkManager/dispatcher.d/. These
# scripts run on connection events (interface up/down, etc.) — currently
# used to nudge waybar's weather module to refresh as soon as wifi is
# back, instead of waiting up to 10 minutes for the next poll.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

for src in "$HERE"/network-dispatcher/*; do
    name=$(basename "$src")
    sudo install -m 755 -o root -g root "$src" "/etc/NetworkManager/dispatcher.d/$name"
done
