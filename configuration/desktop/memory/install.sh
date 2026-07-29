#!/usr/bin/env bash
# Keeps the machine responsive under memory pressure, two ways:
#   - zram: a compressed swap device that lives inside RAM. When memory
#     fills, the coldest pages are compressed in place rather than paged
#     out to the slow SSD, so far more fits before anything gives.
#   - systemd-oomd: NOT used to kill on swap. On zram, swap filling is
#     normal, and oomd's swap-kill picks the cgroup with the largest swap
#     footprint - a long-lived tmux/desktop session - rather than the
#     transient hog, so it logged us out mid-build. The kernel OOM killer
#     is the backstop instead: it kills the hungriest process, not the
#     session's cgroup, so tmux and the compositor survive.
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

# Disarm oomd's swap-based killing (see above): keep the drop-in for a
# documented, easily-reverted limit pinned at 100%, and ManagedOOMSwap=auto
# on the root slice so nothing under it is ever swap-killed.
sudo mkdir -p /etc/systemd/oomd.conf.d /etc/systemd/system/-.slice.d
sudo tee /etc/systemd/oomd.conf.d/orchard.conf >/dev/null <<'EOF'
[OOM]
SwapUsedLimit=100%
EOF
sudo tee /etc/systemd/system/-.slice.d/10-oomd.conf >/dev/null <<'EOF'
[Slice]
ManagedOOMSwap=auto
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now systemd-oomd.service
# Bring the zram device up now; the generator otherwise creates it at boot.
sudo systemctl start systemd-zram-setup@zram0.service
