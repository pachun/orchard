#!/usr/bin/env bash
# Wi-Fi reliability. Owns NetworkManager tuning that keeps the connection
# surviving suspend/resume; the pickers live elsewhere (system's
# wifi-menu, waybar's status module).
#
# The only tuning so far is for MediaTek cards — the Framework 13's
# MT7925 wakes from s2idle deaf, half the time failing the first WPA
# handshakes, which NetworkManager reads as a wrong password: it prompts
# a lock screen that can't answer, fails the activation, and blocks
# autoconnect until the network is reconnected by hand. Intel cards (XPS,
# Macs) wake instantly and never hit this, so the defaults are gated on
# the card being present.
# Idempotent.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

mediatek_pci_vendor=14c3
mediatek_wifi_is_present() {
    lspci -d "$mediatek_pci_vendor:" 2>/dev/null | grep -qi network
}

drop_in=/etc/NetworkManager/conf.d/mediatek-wifi.conf
repo_drop_in="$HERE/mediatek-wifi.conf"

apply_connection_defaults() {
    sudo install -Dm644 "$repo_drop_in" "$drop_in"
    sudo nmcli general reload
}

if ! mediatek_wifi_is_present; then
    echo "wifi: no MediaTek card; skipping."
    exit 0
fi

cmp -s "$repo_drop_in" "$drop_in" || apply_connection_defaults
