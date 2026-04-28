#!/usr/bin/env bash
# Build and install palm-filter as a system service. Idempotent — re-runs pick
# up source/unit changes via systemctl restart.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

sudo pacman -S --needed --noconfirm rust
( cd "$HERE" && cargo build --release )
sudo install -m 755 "$HERE/target/release/palm-filter" /usr/local/bin/palm-filter
sudo install -m 644 "$HERE/palm-filter.service" /etc/systemd/system/palm-filter.service
sudo systemctl daemon-reload
sudo systemctl enable palm-filter.service
sudo systemctl restart palm-filter.service
