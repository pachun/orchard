#!/usr/bin/env bash
# Intel GPU userspace. mesa (OpenGL) arrives for free as a dependency of
# hyprland/chromium/mpv, but these do not and have to be explicit:
#
#   intel-media-driver — the iHD VA-API driver. Without it, video decodes
#     on the CPU (a single 1080p stream costs ~8 W and pegs a core); with
#     it, the GPU's video engine does the work. It's what lets Chromium's
#     VA-API flags in ../chromium/config/chromium-flags.conf actually bind
#     — verify with `vainfo` and chrome://gpu -> "Video Decode: Hardware
#     accelerated". This is the sole home of the GPU decode driver;
#     hardware-agnostic consumers (chromium, media-codecs) don't bundle
#     it, they just use it when it's present.
#   vulkan-intel — the Vulkan driver for the Intel GPU (ANGLE, WebGPU).
#   libva-utils — vainfo, to confirm hardware decode after a rebuild.
#   intel-gpu-tools — intel_gpu_top, to watch GPU engine load live
#     (including the video-decode engine).
#
# The Apple-silicon Mac skips this entirely: its graphics userspace
# comes from the Asahi base install.
set -euo pipefail

. "$TOOLS/machine.sh"

is_apple_silicon && exit 0

# The AMD equivalents (Framework 13): radeonsi's VA-API decode lives in
# libva-mesa-driver, Vulkan in vulkan-radeon; no intel-gpu-tools analogue
# is needed.
if is_amd_cpu; then
  packages=(libva-mesa-driver vulkan-radeon libva-utils)
else
  packages=(intel-media-driver vulkan-intel libva-utils intel-gpu-tools)
fi
sudo pacman -S --needed --noconfirm "${packages[@]}"
