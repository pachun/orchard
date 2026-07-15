#!/usr/bin/env bash
# Keeps the machine responsive under memory pressure, two ways:
#   - zram: a compressed swap device that lives inside RAM. When memory
#     fills, the coldest pages are compressed in place rather than paged
#     out to the slow SSD, so far more fits before anything gives.
#   - systemd-oomd: the last resort. If swap still hits the wall, it kills
#     the single hungriest cgroup instead of letting the whole machine
#     freeze. Configured to act once zram-swap passes 90% used.
# Idempotent.
set -euo pipefail

sudo pacman -S --needed --noconfirm zram-generator

# zram sized at half of RAM (capped at 8 GiB), zstd for a good
# compression-ratio / CPU balance.
sudo tee /etc/systemd/zram-generator.conf >/dev/null <<'EOF'
[zram0]
zram-size = min(ram / 2, 8192)
compression-algorithm = zstd
EOF

# Let oomd act on swap pressure system-wide: a global swap limit, plus
# ManagedOOMSwap=kill on the root slice (inherited by everything under
# it) so the limit actually has teeth.
sudo mkdir -p /etc/systemd/oomd.conf.d /etc/systemd/system/-.slice.d
sudo tee /etc/systemd/oomd.conf.d/orchard.conf >/dev/null <<'EOF'
[OOM]
SwapUsedLimit=90%
EOF
sudo tee /etc/systemd/system/-.slice.d/10-oomd.conf >/dev/null <<'EOF'
[Slice]
ManagedOOMSwap=kill
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now systemd-oomd.service
# Bring the zram device up now; the generator otherwise creates it at boot.
sudo systemctl start systemd-zram-setup@zram0.service
