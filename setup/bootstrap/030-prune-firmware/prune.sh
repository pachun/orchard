#!/usr/bin/env bash
# The asahi-alarm installer pulls in `linux-firmware` (a meta-package
# with no files of its own) which depends on every per-vendor
# sub-package — Intel CPUs, NVIDIA/AMD/Radeon GPUs, Atheros/MediaTek/
# Realtek wifi, etc. None of that hardware exists on Apple Silicon,
# so ~750 MB of firmware blobs sit on disk doing nothing.
#
# Removing the sub-packages alone isn't enough: `linux-firmware`
# lists them as hard deps, so the next `pacman -Syu` would re-pull
# them. So we also remove the meta-package itself. The vendor
# sub-packages still on the system after this script (broadcom,
# cirrus, other) stay because they're either actively used (broadcom
# for BCM4377 wifi/BT) or small enough not to bother with (other is
# a catch-all).
#
# Idempotent: pacman -R errors when the package isn't installed; the
# filter below skips uninstalled entries so re-running is safe.
set -euo pipefail

PRUNE=(
  linux-firmware
  linux-firmware-amdgpu
  linux-firmware-atheros
  linux-firmware-intel
  linux-firmware-mediatek
  linux-firmware-nvidia
  linux-firmware-radeon
  linux-firmware-realtek
)

# Filter to only-installed so pacman doesn't error on the whole batch
# if even one is already gone.
to_remove=()
for p in "${PRUNE[@]}"; do
  if pacman -Qi "$p" >/dev/null 2>&1; then
    to_remove+=("$p")
  fi
done

if [ "${#to_remove[@]}" -gt 0 ]; then
  pacman -Rns --noconfirm "${to_remove[@]}"
fi
