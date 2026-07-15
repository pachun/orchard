#!/usr/bin/env bash
# Keeps the system clock synced over the network with systemd-timesyncd.
# Nothing else syncs it (NetworkManager doesn't), so without this the
# clock drifts — which breaks TLS handshakes and time-based 2FA codes.
# The service ships with systemd; this just enables it. (The base
# installer runs `timedatectl set-ntp true`, but only in the live ISO, so
# it never carried onto the installed system.)
# Idempotent.
set -euo pipefail

sudo systemctl enable --now systemd-timesyncd.service
