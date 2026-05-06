#!/usr/bin/env bash
# Enable + start the bluez daemon. Idempotent.
#
# `bluetooth.service` is the system unit that runs bluetoothd; without
# it `bluetoothctl` returns "No default controller available". Pairing
# state is persisted under /var/lib/bluetooth so devices stay paired
# across reboots without further setup.
set -euo pipefail

sudo systemctl enable --now bluetooth.service
