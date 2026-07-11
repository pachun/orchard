#!/usr/bin/env bash
# IPU7 (Panther Lake) webcam — Dell XPS only. Mainline brings up the IPU7
# ISYS + firmware but never binds the OV08X40 sensor: the sensor's ACPI
# chain depends on intel_cvs (which claims INTC10E1 / CVSS), and intel_cvs
# isn't upstream. This installs that driver, forces the module load order
# the sensor needs, then exposes the camera as an ordinary /dev/video
# webcam — flipped 180° (the sensor is mounted inverted) via a libcamera →
# v4l2loopback relay you start on demand with `camera on` / `camera off`.
#
# Background: github.com/intel/vision-drivers (intel_cvs is the #1 blocker),
# CachyOS/linux-cachyos#804, basecamp/omarchy#6000.
# Idempotent.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# This camera only exists on the Dell; Apple-silicon Macs skip it entirely.
. "$TOOLS/machine.sh"
is_apple_silicon && { echo "camera: IPU7 is Dell-only; skipping on Apple silicon."; exit 0; }

# --- Phase 1: make the sensor bind ---------------------------------------
# Build tooling for the DKMS modules, then intel_cvs itself (Intel's own
# vision driver, not yet upstreamed) from the AUR.
sudo pacman -S --needed --noconfirm linux-headers dkms clang llvm
yay -S --needed --noconfirm intel-vision-drivers-dkms-git

# The sensor's i2c bus sits behind the usbio bridge, and intel_cvs must
# claim INTC10E1 before intel_ipu7 probes or the sensor never attaches.
# The psys half is incompatible and has to stay unloaded. Takes effect on
# the next boot (the first desktop bringup reboots anyway).
sudo tee /etc/modprobe.d/ipu7-usbio-order.conf >/dev/null <<'EOF'
softdep intel_ipu7 pre: usbio gpio_usbio i2c_usbio intel_cvs intel_skl_int3472_discrete
blacklist intel_ipu7_psys
EOF

# --- Phase 2: expose it as a right-side-up /dev/video webcam -------------
sudo pacman -S --needed --noconfirm v4l2loopback-dkms gst-plugin-libcamera

# A persistent loopback device apps see as a normal "IPU7 Camera" webcam.
sudo tee /etc/modprobe.d/v4l2loopback.conf >/dev/null <<'EOF'
options v4l2loopback video_nr=33 card_label="IPU7 Camera" exclusive_caps=1
EOF
echo v4l2loopback | sudo tee /etc/modules-load.d/v4l2loopback.conf >/dev/null
sudo modprobe -r v4l2loopback 2>/dev/null || true
sudo modprobe v4l2loopback

# The `camera on|off` command + its on-demand relay service. The service is
# intentionally not enabled: the camera (and its LED) only power up when you
# ask, which doubles as a hardware privacy guarantee.
bash "$TOOLS/link.sh" "$HERE/bin" "$HOME/.local/bin"
bash "$TOOLS/link.sh" "$HERE/systemd" "$HOME/.config/systemd/user"
systemctl --user daemon-reload
