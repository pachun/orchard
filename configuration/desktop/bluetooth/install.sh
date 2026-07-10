#!/usr/bin/env bash
# bluez daemon + bluez-utils CLI, plus the bluez tweaks Apple audio
# devices (AirPods especially) need to actually be useful on Linux.
# Idempotent.
#
# Settings applied to /etc/bluetooth/main.conf:
#
#   [General] Experimental = true
#     Turns on bluez features Apple devices rely on: extended
#     advertisements, LE Resolvable Private Address timeout handling,
#     etc. Without it, AirPods in pairing mode broadcast happily but
#     bluetoothd drops them before they reach `bluetoothctl devices`,
#     so the fuzzel menu never sees them.
#
#   [General] JustWorksRepairing = always
#     Defense-in-depth: lets bluez silently re-establish a JustWorks
#     bond when the peer initiates a re-pair handshake. The default
#     `never` blocks such handshakes. NOTE: this is NOT what fixes
#     the AirPods case-cycle "unbond" symptom — that bug was
#     bluez/bluez#748 (link key never persisted to disk when pair was
#     issued non-interactively without an agent registered), fixed in
#     dotfiles/local/bin/bluetooth-menu's `run_pair` helper. JWR is
#     kept here as a generally-good Apple-device setting.
#
#   [Policy] AutoEnable = true
#     Auto-reconnect to known/trusted devices when the adapter powers
#     on (boot, resume from suspend). Cheap, broadly useful.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

sudo pacman -S --needed --noconfirm bluez bluez-utils

bash "$TOOLS/link.sh" "$HERE/bin" "$HOME/.local/bin"
sudo systemctl enable --now bluetooth.service

# Idempotent INI patcher. Three input states per key: already set to the
# desired value (no-op), commented-out default (uncomment + set), or
# absent entirely (insert after the section header).
sudo sh -c '
    conf=/etc/bluetooth/main.conf
    apply() {
        section=$1; key=$2; value=$3
        if grep -qE "^[[:space:]]*${key}[[:space:]]*=[[:space:]]*${value}[[:space:]]*$" "$conf"; then
            return 0
        fi
        if grep -qE "^[[:space:]]*#[[:space:]]*${key}[[:space:]]*=" "$conf"; then
            sed -i "s|^[[:space:]]*#[[:space:]]*${key}[[:space:]]*=.*|${key} = ${value}|" "$conf"
        elif grep -qE "^[[:space:]]*${key}[[:space:]]*=" "$conf"; then
            sed -i "s|^[[:space:]]*${key}[[:space:]]*=.*|${key} = ${value}|" "$conf"
        else
            sed -i "/^\[${section}\]/a ${key} = ${value}" "$conf"
        fi
    }
    apply General Experimental        true
    apply General JustWorksRepairing  always
    apply Policy  AutoEnable          true
'

sudo systemctl restart bluetooth.service
