#!/usr/bin/env bash
# The UltraFine 5K's Thunderbolt link trains well only occasionally on
# this machine (kernel bug, report in ~/ultrafine-5k-bug-report.md).
# This installs a guard that retries the link until training lands
# well, keeping the desktop calm between attempts. See README.md.
# Idempotent.
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

sudo install -m 755 "$here/ultrafine-bringup.sh" /usr/local/bin/ultrafine-bringup
sudo install -m 644 "$here/ultrafine-bringup.service" /etc/systemd/system/ultrafine-bringup.service
sudo install -m 644 "$here/99-ultrafine-bringup.rules" /etc/udev/rules.d/99-ultrafine-bringup.rules
sudo systemctl daemon-reload
sudo udevadm control --reload
